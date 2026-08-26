#!/usr/bin/env python3
"""Apply App Store settings that fastlane deliver cannot.

Runs on Bitrise, before `fastlane deliver`. Self-contained on purpose: it is copied into
each app repository, so it depends on nothing but `requests` and `cryptography`.

It sets:
  * the age rating override (18+ lives only in ageRatingOverrideV2)
  * the price (free), through a price schedule
  * availability in every territory

deliver handles none of these. Its pricing calls fail against Apple's current API with
"'prices' is not a relationship on the resource 'apps'", and the legacy age rating field
tops out below 18+.

Environment (already present in the Bitrise app's secrets):
  APP_BUNDLE_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_API_KEY_CONTENT (base64 .p8)

Optional:
  GF_AGE_RATING     age rating override, default EIGHTEEN_PLUS
  GF_BASE_TERRITORY base territory for pricing, default USA
  GF_SKIP           comma-separated steps to skip: age_rating, pricing, availability
"""

from __future__ import annotations

import base64
import json
import os
import sys
import time

import requests
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

ROOT = "https://api.appstoreconnect.apple.com"
V1 = f"{ROOT}/v1"

# Every answer is "absent" — these apps contain none of it. The 18+ rating comes from the
# override, not from the questionnaire, but Apple will not accept an override until the
# questionnaire has been answered.
BASELINE = {
    "alcoholTobaccoOrDrugUseOrReferences": "NONE",
    "contests": "NONE",
    "gamblingSimulated": "NONE",
    "horrorOrFearThemes": "NONE",
    "matureOrSuggestiveThemes": "NONE",
    "medicalOrTreatmentInformation": "NONE",
    "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE",
    "sexualContentOrNudity": "NONE",
    "violenceCartoonOrFantasy": "NONE",
    "violenceRealistic": "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    "gunsOrOtherWeapons": "NONE",
    "healthOrWellnessTopics": False,
    "gambling": False,
    "unrestrictedWebAccess": False,
    "ageAssurance": False,
    "advertising": False,
    "userGeneratedContent": False,
    "messagingAndChat": False,
    "parentalControls": False,
    "lootBox": False,
}


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")


def make_token(key_pem: str, key_id: str, issuer_id: str) -> str:
    key = serialization.load_pem_private_key(key_pem.encode(), password=None)
    now = int(time.time())
    header = b64url(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}).encode())
    payload = b64url(
        json.dumps(
            {"iss": issuer_id, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"}
        ).encode()
    )
    signature = key.sign(f"{header}.{payload}".encode(), ec.ECDSA(hashes.SHA256()))
    r, s = decode_dss_signature(signature)
    size = (key.curve.key_size + 7) // 8
    raw = r.to_bytes(size, "big") + s.to_bytes(size, "big")
    return f"{header}.{payload}.{b64url(raw)}"


class Asc:
    def __init__(self, token: str) -> None:
        self.headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    def call(self, method: str, path: str, *, params=None, body=None):
        url = path if path.startswith("http") else f"{V1}{path}"
        resp = requests.request(method, url, headers=self.headers, params=params, json=body, timeout=90)
        if not resp.ok:
            raise SystemExit(f"App Store Connect {method} {path} failed ({resp.status_code}): {resp.text[:600]}")
        return resp.json() if resp.content.strip() else {}

    def all_pages(self, path: str, params=None):
        out, payload = [], self.call("GET", path, params=params)
        out += payload.get("data") or []
        while (nxt := (payload.get("links") or {}).get("next")):
            payload = self.call("GET", nxt)
            out += payload.get("data") or []
        return out


def resolve_app(asc: Asc, bundle_id: str) -> str:
    rows = asc.call("GET", "/apps", params={"filter[bundleId]": bundle_id, "limit": 200}).get("data") or []
    for row in rows:
        if (row.get("attributes") or {}).get("bundleId") == bundle_id:
            return row["id"]
    raise SystemExit(f"No App Store Connect record for {bundle_id}. Create it before delivering.")


def set_age_rating(asc: Asc, app_id: str, target: str) -> None:
    infos = asc.call(
        "GET", f"/apps/{app_id}/appInfos", params={"limit": 10, "include": "ageRatingDeclaration"}
    )
    declaration_id = next(
        (item["id"] for item in (infos.get("included") or []) if item.get("type") == "ageRatingDeclarations"),
        None,
    )
    if not declaration_id:
        raise SystemExit(f"App {app_id} has no age rating declaration.")

    def patch(attributes: dict) -> None:
        asc.call(
            "PATCH",
            f"/ageRatingDeclarations/{declaration_id}",
            body={"data": {"type": "ageRatingDeclarations", "id": declaration_id, "attributes": attributes}},
        )

    patch(dict(BASELINE))
    # Only V2 may be sent: setting the legacy field alongside it is rejected.
    patch({"ageRatingOverrideV2": target})
    print(f"age rating: {target}")


def set_free(asc: Asc, app_id: str, territory: str) -> None:
    points = asc.all_pages(
        f"/apps/{app_id}/appPricePoints", params={"filter[territory]": territory, "limit": 200}
    )
    price_point = next(
        (p["id"] for p in points if str((p.get("attributes") or {}).get("customerPrice", "")).strip() in ("0", "0.0", "0.00")),
        None,
    )
    if not price_point:
        raise SystemExit(f"No $0 price point for app {app_id} in {territory}.")

    local_id = "${gf-free-price}"
    asc.call(
        "POST",
        "/appPriceSchedules",
        body={
            "data": {
                "type": "appPriceSchedules",
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}},
                    "baseTerritory": {"data": {"type": "territories", "id": territory}},
                    "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
                },
            },
            "included": [
                {
                    "type": "appPrices",
                    "id": local_id,
                    "attributes": {"startDate": None},
                    "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": price_point}}},
                }
            ],
        },
    )
    print(f"pricing: free, based on {territory}")


def set_available_everywhere(asc: Asc, app_id: str) -> None:
    territories = [t["id"] for t in asc.all_pages("/territories", params={"limit": 200})]
    included = [
        {
            "type": "territoryAvailabilities",
            "id": f"${{gf-{t}}}",
            "attributes": {"available": True},
            "relationships": {"territory": {"data": {"type": "territories", "id": t}}},
        }
        for t in territories
    ]
    asc.call(
        "POST",
        f"{ROOT}/v2/appAvailabilities",
        body={
            "data": {
                "type": "appAvailabilities",
                "attributes": {"availableInNewTerritories": True},
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}},
                    "territoryAvailabilities": {
                        "data": [{"type": "territoryAvailabilities", "id": item["id"]} for item in included]
                    },
                },
            },
            "included": included,
        },
    )
    print(f"availability: {len(territories)} territories")


def main() -> int:
    bundle_id = os.environ["APP_BUNDLE_ID"]
    key_pem = base64.b64decode(os.environ["ASC_API_KEY_CONTENT"]).decode()
    token = make_token(key_pem, os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"])

    skip = {s.strip() for s in os.environ.get("GF_SKIP", "").split(",") if s.strip()}
    target = os.environ.get("GF_AGE_RATING", "EIGHTEEN_PLUS")
    territory = os.environ.get("GF_BASE_TERRITORY", "USA")

    asc = Asc(token)
    app_id = resolve_app(asc, bundle_id)
    print(f"app record: {app_id} ({bundle_id})")

    if "age_rating" not in skip:
        set_age_rating(asc, app_id, target)
    if "pricing" not in skip:
        set_free(asc, app_id, territory)
    if "availability" not in skip:
        set_available_everywhere(asc, app_id)

    return 0


if __name__ == "__main__":
    sys.exit(main())
