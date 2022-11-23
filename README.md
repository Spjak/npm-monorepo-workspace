# npm-monorepo-workspace
Example repo for TypeScript mono-repo using npm workspaces

## Setup
Initialize a new project in an empty folder with `npm init`.

Initialize new or existing applications and libraries with

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

## Code
Write, test and debug the applications and libraries in their individual folders.

Npm packages can be installed from the within the folders with normal npm install commands, or alternatively from the root folder with workspace references 
```
npm install uuid -w id-helper
```

Local modules configured as workspaces can be refereced as packages, since the workspace will generate symbolic links in the root node_modules folder.
This means instead of

```
import { IdHelper } from '../../libs/id-helper'
```
it is possible to simply use

```
import { IdHelper } from 'id-helper'
```

To ensure the module is (re)-built whenever the dependent applications are built, a reference is required in the tsconfig.json file of the application.
```
"references": [
    {
        "path": "../../libs/id-helper"
    }
]
```
This will allow `tsc -b` to build both the application and the module it depends on.

This is mainly useful when working locally and is not required when publishing.


## Publish
Workspaces makes it simple to execute scripts across every workspace in the project.
Create scritps for building in the root `package.json` 
```
"scripts": {
    "build-all": "npm run build --workspaces --if-present",
    "install-all": "npm ci --workspaces --if-present",
    "lambda-build-all": "npm run lambda-build --workspaces --if-present"
  },
```
and add the corresponding scripts in each of the child `package.json` files
```
"scripts": {
    "lambda-build": "esbuild index.ts --bundle --minify --sourcemap --platform=node --target=es2020 --outfile=dist/index.js",
    "build": "tsc"
}
```

Instead of running `npm install` in each and every folder, the `npm run install-all` script aggregates this.
Similarly, `npm run build-all` will build every module.

Importantly, with the `--if-present` argument, if one or more workspaces are missing scripts, or missing all together, the script will simply ignore them. This means it is possible to only copy relevant workspaces into the build process and still use the same commands to build those.

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
Use the Dockerfile to build a specific application from the root directory, by providing the application name as a build argument

```
docker build --build-arg APP_NAME=user-app -t user-app:latest .
```

Add a .dockerignore file to avoid copying unnecessary files into the build image.

```
**/node_modules
**/build
```

Since only the one application is copied into the `builder` image, npm packages used by other applications will not be installed.
This can be verfied by adding `RUN echo $(ls ./node_modules)` into the Dockerfile after the install commands and building the `shop-app`. This will not include the `pretty-format` package, even though it is referenced in the root `package-lock.json` file, because only `user-app` uses the package.