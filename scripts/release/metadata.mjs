import { execFileSync } from 'node:child_process';
import { readdirSync, readFileSync } from 'node:fs';

const pubspecPath = 'apps/mobile/pubspec.yaml';
const metadataPath = 'apps/mobile/release-meta.json';
const migrationsPath = 'supabase/migrations';
const semver = /^(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$/;
const emoji = /[\p{RGI_Emoji}\u20e3\ufe0f]/v;
const maxInteger = 2_147_483_647;
const git = (...args) => execFileSync('git', args, { encoding: 'utf8' }).trim();

function versionParts(version, name) {
  if (typeof version !== 'string' || version !== version.trim() || !semver.test(version)) {
    throw new Error(`${name} must be a version in X.Y.Z format`);
  }
  const parts = version.split('.').map(Number);
  if (parts.some(part => part > maxInteger)) {
    throw new Error(`${name} exceeds the maximum version component`);
  }
  return parts;
}

function compareVersions(left, right) {
  return left[0] - right[0] || left[1] - right[1] || left[2] - right[2];
}

function readPubspec(pubspec, expectedVersion, source) {
  const value = pubspec.match(/^version:[ \t]*(['"]?)([^'"\s#]+)\1[ \t]*(?:#.*)?\r?$/m)?.[2];
  const [version, buildText, ...extra] = value?.split('+') ?? [];
  if (expectedVersion !== undefined && version !== expectedVersion) {
    throw new Error(`${source}: pubspec version name is '${version ?? '<none>'}', expected '${expectedVersion}'`);
  }
  const build = Number(buildText);
  if (extra.length || !/^[0-9]+$/.test(buildText ?? '') || build < 1 || build > maxInteger) {
    throw new Error(`${source}: pubspec version requires a positive +buildNumber of at most ${maxInteger}`);
  }
  return { version, build };
}

function readMetadata(latest) {
  const meta = JSON.parse(readFileSync(metadataPath, 'utf8'));
  if (typeof meta?.force_on_major !== 'boolean') {
    throw new Error(`${metadataPath}: force_on_major must be true or false`);
  }
  for (const locale of ['vi', 'en']) {
    const notes = meta.notes?.[locale];
    if (!Array.isArray(notes) || notes.length < 1 || notes.length > 4 ||
        notes.some(note => typeof note !== 'string' || !note.trim() || /[\r\n]/.test(note))) {
      throw new Error(`${metadataPath}: notes.${locale} must contain 1–4 non-blank single-line bullets`);
    }
    if (notes.some(note => emoji.test(note))) {
      throw new Error(`${metadataPath}: notes.${locale} must not contain emoji`);
    }
  }

  const minimums = {};
  for (const platform of ['android', 'ios']) {
    const min = versionParts(meta.min_supported?.[platform], `min_supported.${platform}`);
    const recommended = versionParts(meta.recommended?.[platform], `recommended.${platform}`);
    if (compareVersions(min, recommended) > 0 || compareVersions(recommended, latest) > 0) {
      throw new Error(`${metadataPath}: ${platform} must have min_supported <= recommended <= release version`);
    }
    minimums[platform] = min;
  }
  return { meta, minimums };
}

function checkMigrations(minimums) {
  const unmarked = new Set();
  for (const name of readdirSync(migrationsPath).filter(name => name.endsWith('.sql'))) {
    const path = `${migrationsPath}/${name}`;
    const headers = readFileSync(path, 'utf8').split(/\r?\n/)
      .filter(line => /^\s*--\s*@min_client_version\b/.test(line));
    if (headers.length === 0) unmarked.add(path);
    for (const header of headers) {
      const requirement = header.match(/@min_client_version\s*:\s*(\S+)\s*$/)?.[1];
      const required = versionParts(requirement, `${path} @min_client_version`);
      for (const [platform, minimum] of Object.entries(minimums)) {
        if (compareVersions(minimum, required) < 0) {
          throw new Error(`${path} @min_client_version ${requirement} exceeds min_supported.${platform} (${minimum.join('.')})`);
        }
      }
    }
  }
  return unmarked;
}

function checkPreviousBuild(latest, build, unmarked) {
  let previous;
  for (const line of git('ls-remote', '--tags', '--refs', 'origin').split('\n')) {
    const [sha, ref] = line.trim().split(/\s+/);
    if (!ref?.startsWith('refs/tags/v')) continue;
    const version = ref.slice('refs/tags/v'.length);
    if (!semver.test(version)) continue;
    const parts = versionParts(version, ref);
    if (compareVersions(parts, latest) < 0 && (!previous || compareVersions(parts, previous.parts) > 0)) {
      previous = { sha, ref, version, parts };
    }
  }
  if (!previous) return;

  // Fetch the previous release by ref without creating or changing local tags.
  git('fetch', '--quiet', '--no-tags', '--no-write-fetch-head', 'origin', previous.ref);
  const { build: previousBuild } = readPubspec(git('show', `${previous.sha}:${pubspecPath}`), previous.version, previous.ref);
  if (build <= previousBuild) {
    throw new Error(`+buildNumber ${build} must be greater than ${previousBuild} from v${previous.version}`);
  }

  const newUnmarked = git('diff', '--name-only', '--diff-filter=A', previous.sha, 'HEAD', '--', migrationsPath)
    .split('\n').filter(path => unmarked.has(path));
  if (newUnmarked.length) {
    console.log('NOTICE  Confirm backwards compatibility for new migrations without @min_client_version:');
    for (const path of newUnmarked) console.log(`  ${path}`);
  }
}

try {
  const [command, tag, ...extra] = process.argv.slice(2);
  if (extra.length || (command === 'lint' ? tag !== undefined :
    !['check', 'request'].includes(command) || !tag?.startsWith('v'))) {
    throw new Error('Usage: node scripts/release/metadata.mjs lint | <check|request> vX.Y.Z');
  }
  const tagVersion = tag?.slice(1);
  if (tagVersion !== undefined) versionParts(tagVersion, 'tag');
  const { version, build } = readPubspec(readFileSync(pubspecPath, 'utf8'), tagVersion, pubspecPath);
  const latest = versionParts(version, `${pubspecPath} version`);
  const { meta, minimums } = readMetadata(latest);
  const unmarked = checkMigrations(minimums);

  if (command !== 'request') {
    if (command === 'check') checkPreviousBuild(latest, build, unmarked);
    console.log(`ok    release metadata and pubspec version ${version}+${build}`);
  } else {
    console.log(JSON.stringify({
      p_platform: 'android',
      p_latest: version,
      p_latest_build: build,
      p_recommended: meta.recommended.android,
      p_min_supported: meta.min_supported.android,
      p_force_on_major: meta.force_on_major,
      p_download_url: `https://github.com/hofang42/ourney-releases/releases/download/${tag}/Ourney.apk`,
      p_notes_vi: meta.notes.vi,
      p_notes_en: meta.notes.en,
    }));
  }
} catch (error) {
  console.error(`error: ${error.message}`);
  process.exitCode = 1;
}
