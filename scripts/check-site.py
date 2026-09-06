"""Check generated pages and local links using only the Python standard library."""

import json
import sys
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


class PageLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = set()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.add(attrs["id"])
        if tag == "a" and "name" in attrs:
            self.ids.add(attrs["name"])
        for attr in ("href", "src", "poster"):
            if attrs.get(attr):
                self.links.append(attrs[attr])


def check_site(directory):
    root = Path(directory).resolve()
    if not (root / "index.html").is_file():
        raise ValueError(f"Build the site first: {root}/index.html is missing")
    pages = {}
    for path in root.rglob("*.html"):
        parser = PageLinks()
        parser.feed(path.read_text(encoding="utf-8"))
        pages[path] = parser

    errors = []
    for source, page in pages.items():
        for link in page.links:
            url = urlsplit(link)
            if url.scheme or url.netloc:
                continue
            path = unquote(url.path)
            target = (root / path.lstrip("/")) if path.startswith("/") else (source.parent / path if path else source)
            target = target.resolve()
            if not target.is_relative_to(root):
                errors.append(f"{source.relative_to(root)}: link escapes site: {link}")
                continue
            if target.is_dir():
                target /= "index.html"
            if not target.is_file():
                errors.append(f"{source.relative_to(root)}: missing target: {link}")
            elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
                errors.append(f"{source.relative_to(root)}: missing anchor: {link}")

    posts = json.loads((root / "search.json").read_text(encoding="utf-8"))
    for post in posts:
        for field in ("title", "url", "summary", "category", "tags", "date"):
            if field not in post:
                errors.append(f"Search entry is missing {field}: {post}")
    for listing in ("categories/index.html", "archive/index.html"):
        page = pages.get(root / listing)
        if page:
            listed_urls = set(page.links)
            for post in posts:
                if post.get("url") not in listed_urls:
                    errors.append(f"{listing}: article missing from listing: {post.get('url')}")
    for filename in ("feed.xml", "sitemap.xml"):
        ET.parse(root / filename)
    if errors:
        raise ValueError("\n".join(errors))
    print(f"OK: {len(pages)} HTML pages, {len(posts)} search entries, local links, anchors, feed and sitemap.")


if __name__ == "__main__":
    try:
        check_site(sys.argv[1] if len(sys.argv) > 1 else "_site")
    except (ValueError, OSError, ET.ParseError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
