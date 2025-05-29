module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
     ecmaVersion: 2022,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", {"allowTemplateLiterals": true}],
    // 🔻 DISABLE unwanted rules
    "indent": "off",
    "max-len": "off",
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {
        // You can still apply different rules in test files if you want
      },
    },
  ],
  globals: {},
};
