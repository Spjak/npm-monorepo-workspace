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