/// Base URL of the Classicum website. Override at build time with
/// `--dart-define=API_BASE_URL=https://staging.example.com`.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://classicum.fly.dev',
);
