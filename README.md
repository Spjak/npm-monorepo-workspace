# npm-monorepo-workspace
Example repo for TypeScript mono-repo using npm workspaces

## Setup
Initialize a new project in an empty folder with `npm init`.

Initialize applications and libraries with

```
npm init -w ./apps/user-app
```

Install common dependencies into all workspaces with 

```
npm install --workspaces -D typescript esbuild
```

Add tsconfig.json files to all projects, along the lines of
```
{
  "compilerOptions": {
    "target": "es2016",      
    "module": "commonjs",    
    "declaration": true,     
    "declarationMap": true,  
    "sourceMap": true,       
    "outDir": "./build",     
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,      
    "strict": true,          
    "skipLibCheck": true,
    "composite": true  
  }
}
```
where *"composite": true* is required for libraries.

Create scritps for building in the root `package.json` 
```
"scripts": {
    "build-all": "npm run build --workspaces --if-present",
    "install-all": "npm ci --workspaces --if-present",
    "lambda-build-all": "npm run lambda-build --workspaces --if-present"
  },
```
and each of the child `package.json` files
```
"scripts": {
    "lambda-build": "esbuild index.ts --bundle --minify --sourcemap --platform=node --target=es2020 --outfile=dist/index.js",
    "build": "tsc"
}
```

## Code
Write, test and debug the applications and libraries in their individual folders.

Npm packages can be installed from the within the folders with normal npm install commands, or alternatively from the root folder with 
```
npm install uuid -w id-helper
```

To reference a library from an app, use the direct file reference such as 

```
import { IdHelper } from '../../libs/id-helper'
```

Alternatively, the library can be referenced in the tsconfig.json file
```
"references": [
    {
        "path": "../../libs/id-helper"
    }
]
```
and imported with 

```
import { IdHelper } from 'id-helper'
```

## Publish
Create a Dockerfile in the root project.
Ensure that the folder names match the actual folder structure.

```
FROM public.ecr.aws/lambda/nodejs:16 as builder
ARG APP_NAME

WORKDIR /usr/app

COPY package.json package-lock.json tsconfig.json ./

COPY libs libs
COPY apps/${APP_NAME} apps/${APP_NAME}

RUN npm run install-all
RUN npm run lambda-build-all

RUN cp -r apps/${APP_NAME}/dist /usr/build

FROM node:16-alpine

WORKDIR /usr/app

COPY --from=builder /usr/build ./

CMD ["node", "index.js"]
```
Use the Dockerfile to build each application from the root directory, by providing the application name as a build argument

```
docker build --build-arg APP_NAME=user-app -t user-app:latest .
```

Add a .dockerignore file to avoid copying unnecessary files into the build image.

```
**/node_modules
**/build
```