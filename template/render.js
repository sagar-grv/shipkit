#!/usr/bin/env node
/**
 * ShipKit Template Renderer
 * ==========================
 * Standalone renderer used by setup.sh and setup.ps1.
 * Reads SK_* environment variables (exported by the caller)
 * and renders {{VAR}} + {% if VAR %}...{% endif %} in templates.
 *
 * Usage: node render.js <template-path> <output-path>
 *
 * Environment variables expected (exported by setup script):
 *   SK_PROJECT_NAME, SK_STACK_FRONTEND, SK_NODE_VERSION, etc.
 */

'use strict';

const fs = require('fs');
const path = require('path');

const src = process.argv[2];
const dst = process.argv[3];

if (!src || !dst) {
  console.error('Usage: node render.js <template-path> <output-path>');
  process.exit(1);
}

if (!fs.existsSync(src)) {
  console.error(`Template not found: ${src}`);
  process.exit(1);
}

// Read template
let content = fs.readFileSync(src, 'utf-8');

// Read all SK_* environment variables (stripping the prefix)
const vars = {};
for (const [key, val] of Object.entries(process.env)) {
  if (key.startsWith('SK_')) {
    vars[key.slice(3)] = val;
  }
}

// Replace {{VAR}} placeholders
for (let [varName, val] of Object.entries(vars)) {
  const escaped = varName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const regex = new RegExp(`\\{\\{${escaped}\\}\\}`, 'g');
  content = content.replace(regex, () => String(val ?? ''));
}

// Handle {% if VAR %}...{% endif %}
content = content.replace(
  /\{%\s*if\s+(\w+)\s*%\}([\s\S]*?)\{%\s*endif\s*%\}/g,
  (_, varName, inner) => {
    const val = vars[varName];
    const truthy = Boolean(val) && val !== 'false' && val !== '0' && val !== '';
    return truthy ? inner : '';
  }
);

// Write output
fs.mkdirSync(path.dirname(dst), { recursive: true });
fs.writeFileSync(dst, content, 'utf-8');
console.error(`Rendered: ${src} → ${dst}`);
