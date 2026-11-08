// Run in the builder after npm install; checks the scoped minimatch major override.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { createRequire } = require('node:module');
const rootRequire = createRequire(path.join(process.cwd(), 'package.json'));
const parserRequire = createRequire(rootRequire.resolve('@typescript-eslint/typescript-estree/package.json'));
const { minimatch } = parserRequire('minimatch');
assert.equal(parserRequire('minimatch/package.json').version, '11.0.1');
assert.ok(minimatch('src/index.ts', '**/*.ts'));
assert.ok(!minimatch('src/index.js', '**/*.ts'));
const dir = fs.mkdtempSync(path.join(os.tmpdir(), '9router-lint-'));
try {
  fs.writeFileSync(path.join(dir, 'tsconfig.json'), JSON.stringify({ include: ['*.ts'] }));
  const code = 'const value: number = 1;';
  const filePath = path.join(dir, 'index.ts');
  fs.writeFileSync(filePath, code);
  const { ast, services } = rootRequire('@typescript-eslint/typescript-estree').parseAndGenerateServices(code, {
    filePath, tsconfigRootDir: dir, project: ['./tsconfig.json'],
  });
  assert.equal(ast.type, 'Program');
  assert.ok(services.program.getSourceFile(filePath));
  const dotPath = path.join(dir, '.check.ts');
  fs.writeFileSync(dotPath, code);
  fs.writeFileSync(path.join(dir, 'tsconfig.json'), JSON.stringify({ files: ['index.ts'] }));
  const projectService = rootRequire('@typescript-eslint/typescript-estree').parseAndGenerateServices(code, {
    filePath: dotPath, tsconfigRootDir: dir,
    projectService: { allowDefaultProject: ['*.ts'], defaultProject: 'tsconfig.json' },
  });
  assert.ok(projectService.services.program.getSourceFile(dotPath));
  assert.equal(projectService.ast.type, 'Program');
  console.log('Patched lint dependency, configured project and dot-path project-service checks OK');
} finally {
  fs.rmSync(dir, { recursive: true }); // Only this check's mkdtemp-owned fixture.
}
