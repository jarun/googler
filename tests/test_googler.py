import json
import os
import pathlib
import re
import subprocess

import pytest


ROOT = pathlib.Path(__file__).parent.parent
GOOGLER = ROOT / "googler"

# Load preset options from the environment, in case the testing
# environment need options like --ipv4 or --proxy to connect.
PRESET_OPTIONS = os.getenv("GOOGLER_PRESET_OPTIONS", "").split()


class GooglerResults:
    def __init__(self, argv):
        self.argv = argv
        json_output = subprocess.check_output(
            [str(GOOGLER), *PRESET_OPTIONS, "--debug", "--json", *argv]
        ).decode("utf-8")
        self.results = json.loads(json_output)
        assert self.results, "no results"

    def all_should(self, predicate):
        # Using a loop for better error reporting.
        for result in self.results:
            assert predicate(result)

    def some_should(self, predicate):
        assert any(map(predicate, self.results))


GR = GooglerResults


@pytest.mark.parametrize("query", ["english", "中文"])
def test_default_search(query):
    def have_url_title_and_abstract(result):
        return bool(
            result.get("url") and result.get("title") and ("abstract" in result)
        )

    def have_matched_keywords(result):
        return bool(result.get("matches"))

    gr = GR([query])
    gr.all_should(have_url_title_and_abstract)
    gr.some_should(have_matched_keywords)


def test_news_search():
    def have_metadata(result):
        return bool(result.get("metadata"))

    def have_time_info_in_metadata(result):
        return re.search(r"(hour|days)? ago", result.get("metadata", "")) is not None

    gr = GR(["--news", "--lang=en", "google"])
    gr.all_should(have_metadata)
    gr.some_should(have_time_info_in_metadata)


def test_videos_search():
    def be_from_youtube(result):
        return re.match(r"https://(www\.)?youtube.com/", result["url"]) is not None

    def have_uploader_in_metadata(result):
        return "Uploaded by" in result.get("metadata", "")

    gr = GR(["--videos", "--lang=en", "olympics youtube"])
    gr.some_should(be_from_youtube)
    gr.some_should(have_uploader_in_metadata)


def test_site_search():
    def be_from_wikipedia(result):
        return result["url"].startswith("https://en.wikipedia.org")

    GR(["--site=en.wikipedia.org", "google"]).all_should(be_from_wikipedia)
    GR(["site:en.wikipedia.org google"]).all_should(be_from_wikipedia)


@pytest.mark.parametrize("tld", ["in", "de"])
def test_tld_option(tld):
    # Just a lame test to make sure there are results.
    GR(["--tld", tld, "google"])


def test_exact_option():
    def have_gogole_in_title_or_abstract(result):
        return (
            "gogole" in result["title"].lower()
            or "gogole" in result["abstract"].lower()
        )

    gr = GR(["--exact", "gogole"])
    gr.some_should(have_gogole_in_title_or_abstract)


def test_time_option():
    def have_time_in_metadata(result):
        return (
            re.search(r"hours?|days?|(?P<year>\b\d{4}\b)", result.get("metadata", ""))
            is not None
        )

    gr = GR(["--time=y1", "--lang=en", "google"])
    gr.some_should(have_time_in_metadata)


def test_from_to_options():
    def have_year_2019_in_metadata(result):
        return "2019" in result.get("metadata", "")

    gr = GR(["--from=01/01/2019", "--to=12/31/2019", "--lang=en", "google"])
    # One would expect all results to have 2019 in metadata, but
    # sometimes some results just don't have that line for whatever reason:
    # https://github.com/zmwangx/googler/runs/704110651?check_suite_focus=true
    gr.some_should(have_year_2019_in_metadata)
