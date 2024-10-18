#!/usr/bin/env node

import inquirer from "inquirer";
import { execSync } from "child_process";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

// Tạo __dirname tương tự như trong môi trường CommonJS
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Function to prompt the user to choose between ReactJS (with Vite) and NextJS
const askFrameworkChoice = async () => {
  const answers = await inquirer.prompt([
    {
      type: "list",
      name: "framework",
      message: "Which framework do you want to use?",
      choices: ["ReactJS (with Vite)", "NextJS"],
    },
    {
      type: "input",
      name: "projectName",
      message: "What is your project name?",
      validate: function (input) {
        if (input === "" || /\s/.test(input)) {
          return "Project name cannot be empty or contain spaces.";
        }
        return true;
        tes;
      },
    },
  ]);

  return answers;
};

// Function to ask about Global Styling
const askStylingChoice = async () => {
  const stylingAnswer = await inquirer.prompt([
    {
      type: "list",
      name: "styling",
      message: "Would you like to use other styling (Global CSS is default)?",
      choices: ["Tailwind CSS", "Styled Components", "No"],
    },
  ]);

  return stylingAnswer;
};

// Function to ask about State Management
const askStateManagementChoice = async () => {
  const stateManagementAnswer = await inquirer.prompt([
    {
      type: "list",
      name: "stateManagement",
      message:
        "Would you like to use other state management (React Context is default)?",
      choices: ["Redux Toolkit", "Zustand", "No"],
    },
  ]);

  return stateManagementAnswer;
};

// Function to ask if the user wants to use Styled Components
const askStyledComponentChoice = async () => {
  const styledComponentAnswer = await inquirer.prompt([
    {
      type: "list",
      name: "styledComponent",
      message: "Would you like to use Styled Components?",
      choices: ["Yes", "No"],
    },
  ]);

  return styledComponentAnswer;
};

// Function to check if tailwindcss is installed in package.json
const isTailwindCSSInstalled = (projectName) => {
  const packageJsonPath = path.join(process.cwd(), projectName, "package.json");

  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));

  const hasTailwindCSS =
    (packageJson.dependencies && packageJson.dependencies["tailwindcss"]) ||
    (packageJson.devDependencies && packageJson.devDependencies["tailwindcss"]);

  return Boolean(hasTailwindCSS);
};

// Function to check if ESLint is installed in package.json
const isESLintInstalled = (projectName) => {
  const packageJsonPath = path.join(process.cwd(), projectName, "package.json");

  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));

  const hasESLint =
    (packageJson.dependencies && packageJson.dependencies["eslint"]) ||
    (packageJson.devDependencies && packageJson.devDependencies["eslint"]);

  return Boolean(hasESLint);
};

// Function to run commands in the newly created project
const runCommandsInProject = (projectName, commands) => {
  const projectPath = path.join(process.cwd(), projectName);
  commands.forEach((command) => {
    console.log(`Running: ${command}`);
    execSync(command, { stdio: "inherit", cwd: projectPath });
  });
};

// Function to generate folder and config files
const generateFoldersAndFiles = (
  projectName,
  stateManagement,
  styling,
  framework,
  isUseStyledComponent
) => {
  const projectPath = path.join(process.cwd(), projectName);
  const srcPath = path.join(projectPath, "src");

  // Create necessary folders inside src
  const folders = [
    "components",
    "config",
    "constants",
    "features",
    "helpers",
    "hooks",
    "libs",
    "stores",
    "theme",
    "types",
  ];

  folders.forEach((folder) => {
    fs.mkdirSync(path.join(srcPath, folder), { recursive: true });
    fs.writeFileSync(
      path.join(srcPath, folder, "index.ts"),
      `// ${folder} index file`
    );
  });

  // Commitlint config
  const commitLintConfig = `
module.exports = {
  extends: ['@commitlint/config-conventional'],
};
    `;
  fs.writeFileSync(
    path.join(projectPath, ".commitlintrc.cjs"),
    commitLintConfig
  );
  console.log("Commitlint configuration generated.");

  // Prettier config
  const prettierConfig = `
{
  "semi": true,
  "tabWidth": 2,
  "printWidth": 100,
  "singleQuote": false,
  "trailingComma": "none"
}
    `;
  fs.writeFileSync(path.join(projectPath, ".prettierrc"), prettierConfig);
  console.log("Prettier configuration generated.");

  // ESLint config
  const eslintConfig = `
{
  "extends": ["next", "prettier"],
  "plugins": ["@typescript-eslint"],
  "rules": {
    "max-lines": ["error", { "max": 250, "skipBlankLines": true, "skipComments": true }],
    "import/prefer-default-export": "off",
    "no-console": "warn",
    "no-var": "error",
    "no-html-link-for-pages": "off",
    "@typescript-eslint/no-unused-vars": "warn"
  }
}`;
  fs.writeFileSync(path.join(projectPath, ".eslintrc"), eslintConfig);
  console.log("ESLint configuration generated.");

  // Generate styling and state management config based on user choice
  if (framework === "ReactJS (with Vite)" && styling === "Tailwind CSS") {
    const tailwindConfig = `
/** @type {import('tailwindcss').Config} */
export default {
 content: [
    "index.html",
    "./src/**/*.{js,ts,jsx,tsx}"
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
    `;

    fs.writeFileSync(
      path.join(projectPath, "tailwind.config.js"),
      tailwindConfig
    );

    // Add @tailwind directives to index.css
    const indexCssPath = path.join(srcPath, "index.css");
    const tailwindDirectives = `
@tailwind base;
@tailwind components;
@tailwind utilities;
     `;
    fs.appendFileSync(indexCssPath, tailwindDirectives);

    console.log("Tailwind CSS configuration generated.");
  } else if (framework === "NextJS" && isUseStyledComponent === "Yes") {
    const styledComponentsRegistryForNext = `
    import React, { PropsWithChildren, useState } from 'react'
    import { useServerInsertedHTML } from 'next/navigation'
    import { ServerStyleSheet, StyleSheetManager } from 'styled-components'
    
    const StyledComponentsRegistry = ({ children }: PropsWithChildren) => {
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
      `;
    fs.writeFileSync(
      path.join(srcPath, "libs", "StyledComponentsRegistry.tsx"),
      styledComponentsRegistryForNext
    );
    console.log("Styled Components configuration generated.");
  } else if (styling === "Styled Components") {
    const styledComponentsRegistry = `
    import React, { useState } from "react";
    import { ServerStyleSheet, StyleSheetManager } from "styled-components";
    
    export default function StyledComponentsRegistry({ children }: { children: React.ReactNode }) {
      const [styledComponentsStyleSheet] = useState(() => new ServerStyleSheet());
    
      if (typeof window !== "undefined") return <>{children}</>;    
        return (
            <StyleSheetManager sheet={styledComponentsStyleSheet.instance}>{children}</StyleSheetManager>
        );
    }`;
    fs.writeFileSync(
      path.join(srcPath, "libs", "StyledComponentsRegistry.tsx"),
      styledComponentsRegistry
    );
    console.log("Styled Components configuration generated.");
  }

  if (stateManagement === "Redux Toolkit") {
    const reduxStore = `
import { configureStore } from '@reduxjs/toolkit';

export const store = configureStore({
  reducer: {},
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
    `;
    const reduxHooks = `
import { TypedUseSelectorHook, useDispatch, useSelector } from 'react-redux';
import type { RootState, AppDispatch } from './store';

// Use throughout your app instead of plain \`useDispatch\` and \`useSelector\`
export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
    `;
    fs.writeFileSync(path.join(srcPath, "stores", "store.ts"), reduxStore);
    fs.writeFileSync(path.join(srcPath, "stores", "hooks.ts"), reduxHooks);
    console.log("Redux Toolkit configuration generated.");
  } else if (stateManagement === "Zustand") {
    const zustandStore = `
import { create} from 'zustand';

interface StoreState {
  count: number;
  increment: () => void;
}

export const useStore = create<StoreState>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}));
    `;
    fs.writeFileSync(path.join(srcPath, "stores", "useStore.ts"), zustandStore);
    console.log("Zustand configuration generated.");
  }
};

// Function to create and setup project
const createProject = async () => {
  const { framework, projectName } = await askFrameworkChoice();
  let frameworkCommand;

  // Determine the command to create the project based on the framework
  if (framework === "ReactJS (with Vite)") {
    frameworkCommand = `npx create-vite@latest ${projectName} --template react-ts`;
  } else if (framework === "NextJS") {
    frameworkCommand = `npx create-next-app@latest ${projectName}`;
  }

  try {
    console.log(`Creating project ${projectName} using ${framework}...`);
    execSync(frameworkCommand, { stdio: "inherit" });

    // Check if Tailwind CSS is installed in package.json
    const hasTailwindCSS = isTailwindCSSInstalled(projectName);

    let commands = [];
    let isUseStyledComponent;

    if (framework === "NextJS" && !hasTailwindCSS) {
      isUseStyledComponent = await askStyledComponentChoice();
      // Ask if the user wants to use Styled Components

      if (isUseStyledComponent === "Yes") {
        commands.push("yarn add styled-components");
        commands.push("yarn add -D @types/styled-components");
        console.log("Styled Components will be installed.");
      } else {
        console.log("Styled Components installation skipped.");
      }
    } else {
      console.log(
        "Tailwind CSS is already installed, skipping Styled Components prompt."
      );
    }

    let styling;
    // Ask for styling choice
    if (framework === "ReactJS (with Vite)") {
      styling = await askStylingChoice();
      // Handle Styling
      if (styling === "Tailwind CSS") {
        commands.push("yarn add tailwindcss postcss autoprefixer");
        commands.push("npx tailwind init -p");
      } else if (styling === "Styled Components") {
        commands.push("yarn add styled-components");
        commands.push("yarn add -D @types/styled-components");
      }
    }

    // Ask for state management choice
    const { stateManagement } = await askStateManagementChoice();

    // Handle State Management
    if (stateManagement === "Redux Toolkit") {
      commands.push("yarn add @reduxjs/toolkit react-redux");
    } else if (stateManagement === "Zustand") {
      commands.push("yarn add zustand");
    }

    // Install ESLint, Prettier, Husky, Commitlint, Lint-Staged
    if (framework === "NextJS") {
      if (!isESLintInstalled(projectName)) {
        commands.push(
          "yarn add -D eslint prettier eslint-config-prettier eslint-plugin-react eslint-config-next eslint-plugin-react-hooks eslint-plugin-react-refresh @typescript-eslint/eslint-plugin @typescript-eslint/parser husky @commitlint/cli @commitlint/config-conventional lint-staged"
        );
      } else {
        commands.push(
          "yarn add -D prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-react-refresh @typescript-eslint/eslint-plugin @typescript-eslint/parser husky @commitlint/cli @commitlint/config-conventional lint-staged"
        );
      }
    }
    if (framework === "ReactJS (with Vite)") {
      commands.push(
        "yarn add -D eslint prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-react-refresh @typescript-eslint/eslint-plugin @typescript-eslint/parser husky @commitlint/cli @commitlint/config-conventional lint-staged"
      );
    }
    commands.push(
      'npx json -I -f package.json -e \'this["lint-staged"]={"*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"]}\''
    );

    //Install Ant Design & icon
    commands.push("yarn add antd @ant-design/icons @ant-design/cssinjs");

    // Init Husky
    commands.push("npx husky");
    commands.push("npx husky init");
    commands.push('echo "npx lint-staged" > .husky/pre-commit');
    commands.push(
      'echo "npx --no -- commitlint --edit $1" > .husky/commit-msg'
    );

    // Run commands inside the new project
    runCommandsInProject(projectName, commands);

    // Generate folders and files based on the selected options
    generateFoldersAndFiles(
      projectName,
      stateManagement,
      styling,
      framework,
      isUseStyledComponent
    );

    console.log(`Project ${projectName} created and setup successfully!`);
  } catch (error) {
    console.error("Error during project creation:", error.message);
  }
};

// Execute the create project function
createProject();
