# Jagex Webshare Replacer

A simple script that checks and replaces your webshare proxies if they are blocked on jagex's website.

![jagex-webshare-replacer](https://github.com/user-attachments/assets/9cf99d07-54d4-4847-826e-213ee6e8297e)

## How to use

1. Download the latest version from the [release](https://github.com/qwbarch/jagex-webshare-replacer/releases) tab.
2. Run the executable file to generate the configuration file.
3. Modify ``config.json`` and set your ``api_key`` and ``plan_ids``. See [below](#configuration) for more details.
4. Run the executable file.

## Configuration

> [!WARNING]
> This program will not run if ``api_key`` and ``plan_ids`` is missing.

| Name                           | Type     | Default | Description                                                                                                                              |
|--------------------------------|----------|---------|------------------------------------------------------------------------------------------------------------------------------------------|
| api_key                        | String   |         | Webshare API Key. Click [here](https://dashboard.webshare.io/userapi/keys) to create a key.                                              |
| plan_ids                       | number[] |         | The proxy plan ids to check. See [below](#finding-plan-ids) for more details.                                                            |
| max_threads                    | number   | 1000    | Maximum number of requests that can run at a single time.                                                                                |
| wait_seconds_after_replacement | number   | 15      | Number of seconds to wait after an attempt to replace proxies before trying again.                                                       |
| replace_with                   | object   |         | See [replacement definitions](https://apidocs.webshare.io/proxy-replacement/proxy_replacement#replacement-definitions) for more options. |

## Finding plan ids

To find your plan id, go to your ``proxy server`` or ``static residential`` page. The plan id is the 8-digit number shown in the picture below.

<img width="1243" height="251" alt="plan_id" src="https://github.com/user-attachments/assets/2987ed92-3eba-427d-90b8-a59fb25fd445" />

## Build binary

If you would like to build the binary from scratch, you will need to install stack (preferably via [ghcup](https://www.haskell.org/ghcup/)).

```
stack build --copy-bins --local-bin-path ./bin
```
