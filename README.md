# Next.js E2B Template

A minimal, style-neutral Next.js starter packaged as an [E2B](https://e2b.dev) sandbox template.

The template ships a single page, no UI framework, no CSS, and no demo content — just the Next.js App Router, TypeScript, ESLint, and a ready-to-use E2B dev-server setup.

## What's inside

- **Next.js 16** with the App Router and Turbopack
- **React 19** and **TypeScript**
- **pnpm 10.20** as the package manager
- **Node.js 24** in the sandbox image
- **ESLint** with `eslint-config-next`
- A single neutral route at `/`
- E2B start/ready scripts so the sandbox boots straight into `next dev`

## Requirements

- Node.js 24+
- pnpm 10.20+
- [E2B CLI](https://e2b.dev/docs/cli) and an E2B account (for building/previewing the template)
- [GitHub CLI](https://cli.github.com) (optional, only for creating the repository)

## Local development

```bash
cd app
pnpm install
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000).

## E2B template

### Build

```bash
e2b template create nextjs-template \
  --dockerfile e2b.Dockerfile \
  --cmd "/home/user/bin/dev-server.sh start" \
  --ready-cmd "/home/user/bin/health-check.sh" \
  --cpu-count 2 \
  --memory-mb 2048
```

### Preview

```bash
# PowerShell
$env:E2B_API_KEY = "e2b_..."

pnpm preview          # interactive sandbox + live preview
pnpm preview:verify   # headless create -> verify -> kill
```

The preview script reads `E2B_TEMPLATE` and defaults to `nextjs-template`.

## Project structure

```
.
├── app/                     # Next.js application
│   ├── src/app/
│   │   ├── layout.tsx       # root layout and metadata
│   │   └── page.tsx         # single neutral page
│   ├── public/              # static assets
│   └── package.json
├── sandbox-scripts/
│   ├── dev-server.sh        # start/stop/restart the dev server
│   ├── health-check.sh      # HTTP readiness probe
│   └── verify-template.sh   # sandbox self-check
├── e2b.Dockerfile           # E2B template image
├── e2b.toml                 # template metadata
└── try-preview.mjs          # interactive E2B preview
```

## Scripts

### Root

| Command              | Description                                |
| -------------------- | ------------------------------------------ |
| `pnpm preview`       | Create a sandbox and open an interactive preview |
| `pnpm preview:verify`| Run a headless end-to-end template check   |

### `app/`

| Command       | Description                  |
| ------------- | ---------------------------- |
| `pnpm dev`    | Start the development server |
| `pnpm build`  | Create a production build    |
| `pnpm start`  | Serve the production build   |
| `pnpm lint`   | Run ESLint                   |

## Notes

- The dev server binds `0.0.0.0:3000` so E2B preview networking can reach it.
- `pnpm-workspace.yaml` approves the native build scripts required by Next.js (`sharp`, `unrs-resolver`).
- `.e2bignore` and `.dockerignore` keep `node_modules`, `.next`, environment files, and logs out of the build context.
- The starter intentionally has no styling. Add Tailwind, CSS Modules, or any UI library when you need it.

## License

MIT — see [LICENSE](LICENSE).
