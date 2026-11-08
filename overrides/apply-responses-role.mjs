// Apply before Next builds; fail closed if upstream changes the patch location.
import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

export function patchResponsesRole(source) {
  const original = 'export function openaiResponsesToOpenAIResponse(chunk, state) {';
  if (source.includes('function convertResponsesToOpenAIResponse(')) {
    throw new Error('Responses role patch: already applied');
  }
  if (source.split(original).length !== 2) {
    throw new Error('Responses role patch: expected exactly one translator entry point');
  }
  return source.replace(original, `export function openaiResponsesToOpenAIResponse(chunk, state) {
  const result = convertResponsesToOpenAIResponse(chunk, state);
  if (result?.choices?.[0]?.delta && !state.responsesAssistantRoleSent) {
    result.choices[0].delta.role = ROLE.ASSISTANT;
    state.responsesAssistantRoleSent = true;
  }
  return result;
}

function convertResponsesToOpenAIResponse(chunk, state) {`);
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  const path = resolve(process.argv[2] || '/app/code/open-sse/translator/response/openai-responses.js');
  await writeFile(path, patchResponsesRole(await readFile(path, 'utf8')));
}
