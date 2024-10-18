#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Make the script executable for next run
chmod +x "$0"

# Prompt for project name
echo "What is your project name?"
read project_name

# Check if the project name is not empty and does not contain spaces
if [[ -z "$project_name" || "$project_name" =~ \  ]]; then
  echo "Project name cannot be empty or contain spaces. Exiting..."
  exit 1
fi

# Install NextJS in a subdirectory with the project name
yarn create next-app $project_name
cd $project_name

# Install dev dependencies
yarn add -D prettier eslint-config-prettier eslint-plugin-prettier @typescript-eslint/eslint-plugin lint-staged husky @commitlint/config-conventional @commitlint/cli plop dayjs antd @types/antd @ant-design/cssinjs @ant-design/icons @ant-design/nextjs-registry react-redux @reduxjs/toolkit styled-components babel-plugin-styled-components

# Check if .eslint.json file exists and remove it
if [ -f ".eslintrc.json" ]; then
  rm .eslintrc.json
fi

# Create ESLint config file
cat > .eslintrc <<EOL
{
  "extends": ["next", "prettier"],
  "plugins": ["@typescript-eslint"],
  "rules": {
    "max-lines": ["error", { "max": 150, "skipBlankLines": true, "skipComments": true }],
    "import/prefer-default-export": "off",
    "no-console": "warn",
    "no-var": "error",
    "no-html-link-for-pages": "off",
    "@typescript-eslint/no-unused-vars": "warn"
  }
}
EOL

# Create ESLint ignore file
cat > .eslintignore <<EOL
.next
dist
node_modules/
EOL

# Create Prettier config file
cat > .prettierrc <<EOL
{
  "arrowParens": "always",
  "bracketSpacing": true,
  "embeddedLanguageFormatting": "auto",
  "htmlWhitespaceSensitivity": "css",
  "insertPragma": false,
  "jsxSingleQuote": true,
  "printWidth": 80,
  "proseWrap": "preserve",
  "quoteProps": "as-needed",
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "all",
  "useTabs": false,
  "vueIndentScriptAndStyle": false
}
EOL

# Create Prettier ignore file
cat > .prettierignore <<EOL
build/*
dist/*
public/*
.next/*
node_modules/*
package.json
*.log
EOL

# Create CommitLint config file
cat > .commitlintrc.cjs <<EOL
module.exports = {extends: ['@commitlint/config-conventional']};
EOL

# Add Lint-Staged config to package.json
npx json -I -f package.json -e 'this["lint-staged"]={"*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"]}'

# Initialize Husky and create hooks
npx husky
npx husky init

# Add pre-commit hook for lint-staged   
echo "npx lint-staged" > .husky/pre-commit

# Add commit-msg hook for CommitLint
echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg

# Add plop to package.json scripts and run plop
echo "Adding plop to package.json scripts..."
npx json -I -f package.json -e 'this.scripts["plop"] = "plop"'

# Create plopfile.js
cat > plopfile.js <<EOL
module.exports = function (plop) {
  const folders = [
    "components",
    "config",
    "constants",
    "features",
    "helpers",
    "hooks",
    "libs",
    "redux",
    "themes",
    "types",
  ];

  const templates = {
    reduxStore: "src/templates/reduxStoreTemplate.hbs",
    reduxHooks: "src/templates/reduxHooksTemplate.hbs",
    colorHelper: "src/templates/colorHelperTemplate.hbs",
    styledComponentsRegistry: "src/templates/styledComponentsRegistryTemplate.hbs",
    antdTheme: "src/templates/antdThemeTemplate.hbs",
    generalTheme: "src/templates/generalThemeTemplate.hbs",
    globalStyle: "src/templates/globalStyleTemplate.hbs",
    appProviders: "src/templates/appProvidersTemplate.hbs",
  };

  plop.setGenerator("folder", {
    description: "Create multiple folders with index.ts file",
    prompts: [],
    actions: [
      ...createFolders(folders),
      // init redux toolkit
      createAddAction("src/redux/store.ts", templates.reduxStore),
      createAddAction("src/redux/hooks.ts", templates.reduxHooks),
      createAppendAction("src/redux/index.ts", \`export * from './hooks'\nexport * from './store'\n\`),
      // Add helper
      createAddAction("src/helpers/color.helper.ts", templates.colorHelper),
      createAppendAction("src/helpers/index.ts", "export * from './color.helper'"),
      // Add Styled component config
      createAddAction("src/libs/StyledComponentsRegistry.tsx", templates.styledComponentsRegistry),
      createAppendAction("src/libs/index.ts", "export { default as StyledComponentsRegistry } from './StyledComponentsRegistry'"),
      // Add global theme
      createAddAction("src/themes/antdTheme.ts", templates.antdTheme),
      createAddAction("src/themes/generalTheme.ts", templates.generalTheme),
      createAddAction("src/themes/globalStyle.ts", templates.globalStyle),
      createAppendAction("src/themes/index.ts", \`export { default as antdTheme } from './antdTheme'\nexport { default as GlobalStyle } from './globalStyle'\nexport { default as generalTheme } from './generalTheme'\n\`),
      // Add providers
      createAddAction("src/config/AppProviders.tsx", templates.appProviders),
      createAppendAction("src/config/index.ts", "export { default as AppProviders } from './AppProviders'"),
    ],
  });

  function createFolders(folders) {
    return folders.map((folder) => ({
      type: "add",
      path: \`src/\${folder}/index.ts\`,
      template: "",
    }));
  }

  function createAddAction(path, templateFile) {
    return {
      type: "add",
      path,
      templateFile,
    };
  }

  function createAppendAction(path, template) {
    return {
      type: "append",
      path,
      template,
    };
  }
};
EOL


# Create plop templates
mkdir -p src/templates

# Create store.ts file
cat > src/templates/reduxStoreTemplate.hbs <<EOL
import { configureStore } from '@reduxjs/toolkit'

export const store = configureStore({
  reducer: {},
})

export type RootState = ReturnType<typeof store.getState>
// Inferred type: {posts: PostsState, comments: CommentsState, users: UsersState}
export type AppDispatch = typeof store.dispatch

EOL

# Create hooks.ts file
cat > src/templates/reduxHooksTemplate.hbs <<EOL
import { TypedUseSelectorHook, useDispatch, useSelector } from 'react-redux'
import type { RootState, AppDispatch } from './store'

// Use throughout your app instead of plain \`useDispatch\` and \`useSelector\`
export const useAppDispatch: () => AppDispatch = useDispatch
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector
EOL

# Create file color.helper.ts 
cat > src/templates/colorHelperTemplate.hbs <<EOL
export const hexToRgba = (hex: string, alpha = 1): string => {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  if (result) {
    const r = (parseInt(result[1], 16) << 16) & 0xff0000
    const g = (parseInt(result[2], 16) << 8) & 0x00ff00
    const b = parseInt(result[3], 16) & 0x0000ff
    return \`rgba(\${r >> 16}, \${g >> 8}, \${b}, \${alpha})\`
  } else {
    throw new Error('Invalid hex color format')
  }
}
EOL

# Create file StyledComponentsRegistry.tsx
cat > src/templates/styledComponentsRegistryTemplate.hbs <<EOL
'use client'

import { PropsWithChildren, useState } from 'react'
import { useServerInsertedHTML } from 'next/navigation'
import { ServerStyleSheet, StyleSheetManager } from 'styled-components'

const StyledComponentsRegistry = ({ children }: PropsWithChildren) => {
  // Only create stylesheet once with lazy initial state
  // x-ref: https://reactjs.org/docs/hooks-reference.html#lazy-initial-state
  const [styledComponentsStyleSheet] = useState(() => new ServerStyleSheet())

  useServerInsertedHTML(() => {
    const styles = styledComponentsStyleSheet.getStyleElement()
    styledComponentsStyleSheet.instance.clearTag()
    return <>{styles}</>
  })

  if (typeof window !== 'undefined') return <>{children}</>

  return (
    <StyleSheetManager sheet={styledComponentsStyleSheet.instance}>
      {children}
    </StyleSheetManager>
  )
}

export default StyledComponentsRegistry
EOL

# Create files theme config

# antdTheme.ts
cat > src/templates/antdThemeTemplate.hbs <<EOL
import type { ThemeConfig } from 'antd'
import generalTheme from './generalTheme'
import { hexToRgba } from '@/helpers'

const antdTheme: ThemeConfig = {
  token: {
    colorPrimary: generalTheme.colors.primary,
    controlItemBgActive: generalTheme.colors.selectedBackground,
    controlItemBgActiveHover: generalTheme.colors.selectedBackground,
    colorBorder: hexToRgba(generalTheme.colors.primary, 0.3),
    motionUnit: 0.07,
  },
  components: {
    Form: {
      labelColor: hexToRgba(generalTheme.colors.primary, 1),
      fontWeightStrong: 1,
    },
    Input: {
      colorBorder: hexToRgba(generalTheme.colors.primary, 0.5),
    },
    InputNumber: {
      colorBorder: hexToRgba(generalTheme.colors.primary, 0.5),
    },
    Select: {
      colorBorder: hexToRgba(generalTheme.colors.primary, 0.5),
    },
  },
}

export default antdTheme
EOL

# generalTheme.ts
cat > src/templates/generalThemeTemplate.hbs <<EOL
const generalTheme = {
  colors: {
    primary: '#561C24',
    selectedBackground: '#F5EEE6',
  },
  adminHeaderHeight: 60,
  generalSpace: 20,
  adminSidebarWidth: 200,
  headerHeight: 67,
  footerHeight: 140,
  formWidth: 325,
  boxShadow: '0px 4px 22px rgba(0, 0, 0, 0.2)',
}

export default generalTheme
EOL

# globalStyle.ts
cat > src/templates/globalStyleTemplate.hbs <<EOL
import { createGlobalStyle } from 'styled-components'
import generalTheme from './generalTheme'

const GlobalStyle = createGlobalStyle\`
  * {
    box-sizing: border-box;
  }

  body {
    padding: 0;
    margin: 0;
    box-sizing: border-box;
    width: 100% !important;
  }

  .ant-btn-primary {
    background-color: \${generalTheme.colors.primary} !important;
  }

  .ant-btn-default:not(:disabled):not(.ant-btn-disabled):hover {
    color: \${generalTheme.colors.primary} !important;
    border-color: \${generalTheme.colors.primary} !important;
  }
\`
export default GlobalStyle
EOL

# Create App Providers
cat > src/templates/appProvidersTemplate.hbs <<EOL
'use client'

import { store } from '@/redux'
import { antdTheme, generalTheme, GlobalStyle } from '@/themes'
import { ConfigProvider } from 'antd'
import { Provider } from 'react-redux'
import { ThemeProvider } from 'styled-components'
import { AntdRegistry } from '@ant-design/nextjs-registry'
import { StyledComponentsRegistry } from '@/libs'
import { PropsWithChildren } from 'react'

//locale config using for Japanese Project
import jaJP from 'antd/locale/ja_JP'
import 'dayjs/locale/ja'

const AppProviders = ({ children }: Readonly<PropsWithChildren>) => {
  return (
    <Provider store={store}>
      <StyledComponentsRegistry>
        <ThemeProvider theme={generalTheme}>
          <AntdRegistry>
            <ConfigProvider locale={jaJP} theme={antdTheme}>
              <GlobalStyle />
              {children}
            </ConfigProvider>
          </AntdRegistry>
        </ThemeProvider>
      </StyledComponentsRegistry>
    </Provider>
  )
}
export default AppProviders
EOL

# Run plop to set up initial configuration
echo "Running plop..."
yarn plop

# Override layout.tsx with AppProviders
cat > src/app/layout.tsx <<EOL
import { AppProviders } from '@/config'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'NextJS + Antd',
  description: 'NextJS + Antd',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang='en'>
      <body className={inter.className} suppressHydrationWarning={true}>
        <AppProviders>{children}</AppProviders>
      </body>
    </html>
  )
}
EOL

# Update rules tsconfig.json
cat > tsconfig.json <<EOL
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "incremental": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "node",
    "isolatedModules": true,
    "jsx": "preserve",
    "resolveJsonModule": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOL

############# Clean install ############

# Delete PlopJS in package.json
npx json -I -f package.json -e 'delete this.dependencies.plop'
npx json -I -f package.json -e 'delete this.scripts.plop'

# Remove PlopJS 
yarn remove plop

# Change directory to project folder
cd ..

# Remove templates directory, plopfile.js, and setup.sh
rm -rf $project_name/src/templates
rm -f $project_name/plopfile.js
# rm -rf ./setup.sh

# Change to project directory
cd $project_name

echo "Development environment setup is complete!"
