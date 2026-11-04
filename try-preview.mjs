// Try the Next.js sandbox preview interactively.
//
// Usage:
//   $env:E2B_API_KEY = 'e2b_...'        # PowerShell (per session)
//   node try-preview.mjs                 # create sandbox + live preview + interactive commands
//   node try-preview.mjs --verify        # headless check: create -> verify -> kill -> exit
//
// Interactive commands:
//   restart | start | stop | health | exec <shell command> | exit
//   Ctrl+C: kills the sandbox and exits.
import { createInterface } from 'node:readline'
import { Sandbox } from 'e2b'

const TEMPLATE = process.env.E2B_TEMPLATE ?? 'nextjs-template'
const PORT = 3000
const VERIFY = process.argv.includes('--verify')

if (!process.env.E2B_API_KEY) {
  console.error('E2B_API_KEY is not set. In PowerShell:\n  $env:E2B_API_KEY = "e2b_..."')
  process.exit(1)
}

const sbx = await Sandbox.create(TEMPLATE, { timeoutMs: 15 * 60_000 })
const previewUrl = `https://${sbx.getHost(PORT)}`

// keepalive: extend the timeout every 10 minutes so the session survives
const keepalive = setInterval(() => { sbx.setTimeout(15 * 60_000).catch(() => {}) }, 10 * 60_000)

async function shutdown() {
  clearInterval(keepalive)
  await sbx.kill().catch(() => {})
}

if (VERIFY) {
  console.log('sandboxId:', sbx.sandboxId)
  const health = await sbx.commands.run('/home/user/bin/health-check.sh')
  const res = await fetch(previewUrl)
  const body = await res.text()
  console.log('preview fetch:', previewUrl, '->', res.status, '| title ok:', body.includes('Next.js'))
  console.log('in-sandbox health:', health.stdout.trim())
  const restart = await sbx.commands.run('/home/user/bin/dev-server.sh restart')
  console.log('restart:', restart.stdout.trim().replace(/\n/g, ' | '))
  await new Promise(r => setTimeout(r, 8000))
  console.log('health after restart:', (await sbx.commands.run('/home/user/bin/health-check.sh')).stdout.trim())
  await shutdown()
  console.log('VERIFY DONE')
  process.exit(0)
}

console.log('='.repeat(64))
console.log(`  sandbox : ${sbx.sandboxId}`)
console.log(`  template: ${TEMPLATE}`)
console.log(`  preview : ${previewUrl}   <-- open in browser`)
console.log('='.repeat(64))
console.log('commands: restart | start | stop | health | exec <cmd> | exit')
console.log('(Ctrl+C kills the sandbox and exits)')

const rl = createInterface({ input: process.stdin, output: process.stdout, prompt: 'nextjs> ' })
rl.prompt()

rl.on('line', async line => {
  const input = line.trim()
  if (!input) { rl.prompt(); return }
  try {
    switch (input.split(' ')[0]) {
      case 'exit':
      case 'quit':
        await shutdown()
        process.exit(0)
      case 'health':
        console.log((await sbx.commands.run('/home/user/bin/health-check.sh')).stdout.trim())
        break
      case 'start': case 'stop': case 'restart':
        console.log((await sbx.commands.run(`/home/user/bin/dev-server.sh ${input}`)).stdout.trim())
        break
      case 'exec': {
        const r = await sbx.commands.run(input.slice(5))
        const out = (r.stdout + (r.stderr ? `\n${r.stderr}` : '')).trim().split('\n').slice(-30).join('\n')
        console.log(out || '(no output)', r.exitCode !== 0 ? `\n[exit ${r.exitCode}]` : '')
        break
      }
      default:
        console.log(`unknown command: ${input}`)
    }
  } catch (e) {
    console.error('error:', e.message)
  }
  rl.prompt()
}).on('SIGINT', async () => {
  console.log('\nkilling sandbox...')
  await shutdown()
  process.exit(0)
})
