# Indooro Admin Redesign Implementation Notes

The redesigned Admin Platform remains a Quarkus-served static application under `backend/indooro_server/src/main/resources/META-INF/resources/admin`.

## Frontend Stack

- Native ES modules.
- Shared pure helper modules for validation, filtering, readiness checks, and layout validation.
- No runtime CDN dependency for the layout editor.
- No additional frontend build output step; Quarkus serves the assets directly.

React/Vite/TypeScript was considered in the OpenSpec design. The implementation keeps the existing static delivery model for this change because it preserves protected route behavior, avoids build/deployment churn, and allows the UX redesign to land without changing backend packaging.

## Local Commands

- `npm run admin:lint` checks browser JavaScript syntax.
- `npm run admin:typecheck` aliases the same syntax checks for the static stack.
- `npm run admin:test` runs Node unit tests for shared admin/editor helpers.
- `npm run admin:build` validates that static assets are present and syntax-valid.
- `npm run admin:verify` runs all admin frontend checks.

## Route Fallback

Every protected admin route keeps an `index.html` entry point. The subpage files intentionally load the same modular shell and let `app.js` render the page that matches `location.pathname`.

## Compatibility

The redesign reuses existing APIs and keeps public mobile/customer routes unchanged. Layout JSON remains compatible with the existing `shopName`, `gridSize`, `elements`, element geometry, label/category, rotation, lock, access angle, and beacon fields.
