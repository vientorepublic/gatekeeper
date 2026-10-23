import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(path.join(root, 'gatekeeper-backend/package.json'));
const ts = require('typescript');
const excluded = new Set(['node_modules', '.git', '.svelte-kit', 'dist', 'build', 'coverage', '.wrangler']);
const nonEnglish = /[\p{Script=Hangul}\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}]/u;
const issues = [];
const inventory = [];
let comments = 0;
let titles = 0;

function report(file, source, position, rule, text) {
	if (!nonEnglish.test(text)) return;
	const line = source.slice(0, position).split('\n').length;
	issues.push(`${path.relative(root, file)}:${line}: ${rule}: review non-English text; only proper nouns may be exempt`);
}

function rootName(expression) {
	if (ts.isIdentifier(expression)) return expression.text;
	if (ts.isPropertyAccessExpression(expression) || ts.isCallExpression(expression)) return rootName(expression.expression);
	return undefined;
}

function scanScript(file, source, script, offset = 0) {
	const parsed = ts.createSourceFile(file, script, ts.ScriptTarget.Latest, true);
	const seen = new Set();
	function visit(node) {
		const ranges = [
			...(ts.getLeadingCommentRanges(script, node.pos) ?? []),
			...(ts.getTrailingCommentRanges(script, node.end) ?? [])
		];
		for (const range of ranges) {
			if (seen.has(range.pos)) continue;
			seen.add(range.pos);
			comments += 1;
			report(file, source, offset + range.pos, 'comment', script.slice(range.pos, range.end));
		}
		if (ts.isCallExpression(node) && ['describe', 'it', 'test'].includes(rootName(node.expression))) {
			const title = node.arguments[0];
			if (title && (ts.isStringLiteral(title) || ts.isNoSubstitutionTemplateLiteral(title))) {
				titles += 1;
				report(file, source, offset + title.pos, 'test title', title.text);
			}
		}
		ts.forEachChild(node, visit);
	}
	visit(parsed);
}

function scanMatches(file, source, expression) {
	for (const match of source.matchAll(expression)) {
		comments += 1;
		report(file, source, match.index, 'comment', match[0]);
	}
}

function walk(directory) {
	for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
		if (excluded.has(entry.name)) continue;
		const file = path.join(directory, entry.name);
		if (entry.isDirectory()) { walk(file); continue; }
		if (!entry.isFile() || entry.name.endsWith('.tsbuildinfo') || entry.name === 'package-lock.json') continue;
		const extension = path.extname(file);
		if (!['.ts', '.js', '.mjs', '.cjs', '.svelte', '.css', '.json', '.jsonc', '.yaml', '.yml', '.sh', '.md', '.html', '.svg', '.txt'].includes(extension) && entry.name !== 'Dockerfile' && entry.name !== '.env.example' && !['.prettierrc', '.prettierignore', '.gitignore', '.dockerignore', '.npmrc'].includes(entry.name)) continue;
		inventory.push(path.relative(root, file));
		const source = fs.readFileSync(file, 'utf8');
		if (['.ts', '.js', '.mjs', '.cjs', '.jsonc'].includes(extension)) scanScript(file, source, source);
		if (['.svelte', '.html', '.svg', '.txt'].includes(extension)) {
			scanMatches(file, source, /<!--[\s\S]*?-->/g);
			for (const match of source.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/g)) {
				scanScript(file, source, match[1], match.index + match[0].indexOf('>') + 1);
			}
			for (const match of source.matchAll(/<style\b[^>]*>([\s\S]*?)<\/style>/g)) {
				for (const comment of match[1].matchAll(/\/\*[\s\S]*?\*\//g)) {
					comments += 1;
					report(file, source, match.index + match[0].indexOf('>') + 1 + comment.index, 'comment', comment[0]);
				}
			}
		}
		if (extension === '.css') scanMatches(file, source, /\/\*[\s\S]*?\*\//g);
		if (['.yaml', '.yml', '.sh'].includes(extension) || entry.name === 'Dockerfile' || entry.name === '.env.example') scanMatches(file, source, /^\s*#.*$/gm);
	}
}

for (const name of ['gatekeeper-backend', 'gatekeeper-frontend']) walk(path.join(root, name));
console.log(`Inspected ${inventory.length} source/configuration/documentation files, ${comments} comments, and ${titles} test titles.`);
if (process.argv.includes('--inventory')) console.log(inventory.sort().join('\n'));
if (issues.length > 0) {
	console.error(issues.join('\n'));
	process.exitCode = 1;
} else {
	console.log('PASS: no CJK explanatory comments or test titles found. English prose and proper-noun exceptions still require human review.');
}
