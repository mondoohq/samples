# Mondoo GraphQL API Samples

This repository contains sample queries for the Mondoo GraphQL API. The queries are written in GraphQL and can be executed using the [Bruno](https://docs.usebruno.com/).

## Getting Started

- Clone this repository
- Install Bruno
- Setup .env file with your Mondoo API key


## API Key

To get started with the Mondoo API, you need to create an API key. You can create an API key in the Mondoo console. Then create a `.env` file in the root of the repository with the following content:

```
MONDOO_API_TOKEN=your-api-key
MONDOO_ENDPOINT=us.api.mondoo.com
SPACE_MRN=//captain.api.mondoo.app/spaces/mystifying-jennings-299629
ORG_MRN=//captain.api.mondoo.app/organizations/lunalectric
```

> NOTE: While not technically required, it is recommended to use a organization API token with editor permissions to sure all samples work.

## CLI

Follow the installation instructions[https://docs.usebruno.com/bru-cli/overview].

```
bru run search/search.bru --env Mondoo
```

## APP

Follow the installation instructions[https://www.usebruno.com/downloads]. Then you open the collection and run the queries.