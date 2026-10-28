export default {
  extends: ["@commitlint/config-conventional"],
  // Dependabot writes these titles itself, and they can be longer than the
  // limit of a header. A release pull request lints every commit it carries,
  // so one of them would fail the whole release.
  ignores: [
    (message) => /^(ci|chore|build)\((deps|deps-dev)\): bump /.test(message),
  ],
  rules: {
    "type-enum": [
      2,
      "always",
      [
        "feat",
        "fix",
        "docs",
        "style",
        "refactor",
        "perf",
        "test",
        "build",
        "ci",
        "chore",
        "revert",
        "wip",
      ],
    ],
    "subject-case": [
      2,
      "never",
      ["sentence-case", "start-case", "pascal-case", "upper-case"],
    ],
    "subject-empty": [2, "never"],
    "subject-full-stop": [2, "never", "."],
    "type-case": [2, "always", "lower-case"],
    "type-empty": [2, "never"],
  },
};
