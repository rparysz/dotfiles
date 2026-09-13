// Preloaded into markserv via NODE_OPTIONS=--require. Two patches:
//   1. syntax-highlighting aliases highlight.js is missing (```asm)
//   2. a dark theme, since markserv ships light-only with no way to change it
//
// markserv calls `.use(mdItHLJS)` with no options and exposes no config hook,
// so the only way to teach highlight.js new fence names is to patch its
// registry before markserv's markdown-it instance is built.
//
// highlight.js has x86asm/armasm/avrasm/mipsasm but no plain `asm`, which is
// what GitHub and nvim's treesitter both accept — so ```asm fences log
// "Could not find the language 'asm'" and render unhighlighted. Alias instead
// of renaming the fences, which would break those two renderers.
'use strict';

const fs = require('fs');
const path = require('path');

// Failures here must never stop the server — a page with the wrong colours
// still beats no page. MDVIEW_DEBUG=1 surfaces them.
const debug = (what, err) => {
  if (process.env.MDVIEW_DEBUG) console.error(`mdview preload (${what}):`, err.message);
};

try {
  // argv[1] is markserv's cli.js: resolve *its* highlight.js copy, not some
  // other one, or the alias lands on a different module instance. It arrives
  // as the ~/.npm-global/bin symlink, whose directory has no node_modules —
  // realpath first or the lookup finds nothing.
  const from = path.dirname(fs.realpathSync(process.argv[1] || '.'));
  const hljs = require(require.resolve('highlight.js', { paths: [from] }));

  const aliases = {
    x86asm: ['asm', 'assembly', 'nasm'],
  };

  for (const [language, names] of Object.entries(aliases)) {
    if (!hljs.getLanguage(language)) continue;
    const missing = names.filter((n) => !hljs.getLanguage(n));
    if (missing.length) hljs.registerAliases(missing, { languageName: language });
  }
} catch (err) {
  // Never take the server down over syntax highlighting.
  debug('aliases', err);
}

// ── Dark theme ────────────────────────────────────────────────────────────
//
// markserv builds every page from templates/*.html under its own __dirname and
// offers no flag, config file or environment variable to point elsewhere. The
// templates are read through fs.readFile, so wrapping that call is the one
// injection point that survives `npm -g` upgrades. dark.css is scoped to
// `@media (prefers-color-scheme: dark)` and follows the browser's setting.
try {
  const cssPath = path.join(__dirname, 'dark.css');
  const rules = fs.readFileSync(cssPath, 'utf8');

  // MDVIEW_THEME=dark forces dark regardless of the browser, which matters on
  // Linux desktops where the browser does not inherit the system theme.
  // `light` skips injection entirely; anything else follows the browser.
  const theme = process.env.MDVIEW_THEME || 'auto';
  if (theme === 'light') throw new Error('theme=light, nothing to inject');
  const css = theme === 'dark'
    ? rules
    : `@media (prefers-color-scheme: dark) {\n${rules}\n}`;
  const isTemplate = /templates[\\/](markdown|directory|error)\.html$/;
  const origReadFile = fs.readFile;

  fs.readFile = function (file, options, callback) {
    const done = typeof options === 'function' ? options : callback;
    if (typeof file !== 'string' || typeof done !== 'function' || !isTemplate.test(file)) {
      return origReadFile.apply(fs, arguments);
    }

    return origReadFile.call(fs, file, 'utf8', (err, data) => {
      if (err) return done(err);
      // Last stylesheet in <head> wins, so append rather than prepend.
      done(null, data.replace('</head>', `<style>\n${css}\n</style>\n</head>`));
    });
  };
} catch (err) {
  debug('dark theme', err);
}
