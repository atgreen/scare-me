# scare-me
> Transform RHEL Insights reports into tomorrow's headlines!

`scare-me` is a fun tool that generates fake scary news articles based on
your real [RHEL Insights](https://www.redhat.com/en/technologies/management/insights)
reports.  Customize the article by providing your
company name and industry.

```
$ insights-client --show-report | scare-me -n "MyBank" -i banking -o news.html -
```

`scare-me` uses the [llama3 LLM](https://ollama.com/library/llama3)
via a locally-hosted ollama instance (localhost:11434) that you must
deploy separately.

To build `scare-me`, install `ocicl` with homebrew, and run `make`.

`scare-me` is for **entertainment purposes** only!  Here's some sample output:

<p align="center"><img src="news.png"/></p>

Have fun!

AG
