# Crawly
[![Build Status](https://travis-ci.com/oltarasenko/crawly.svg?branch=master)](https://travis-ci.com/oltarasenko/crawly)
[![Coverage Status](https://coveralls.io/repos/github/oltarasenko/crawly/badge.svg?branch=coveralls)](https://coveralls.io/github/oltarasenko/crawly?branch=coveralls)
# Overview

Crawly is an application framework for crawling web sites and
extracting structured data which can be used for a wide range of
useful applications, like data mining, information processing or
historical archival.

# Requirements

1. Elixir  "~> 1.7"
2. Works on Linux, Windows, OS X and BSD

# Install

1. Generate an new Elixir project: `mix new <project_name> --sup`
2. Add Crawly to you mix.exs file
    ```elixir
    def deps do
        [{:crawly, "~> 0.1"}]
    end
    ```
3. Fetch crawly: `mix deps.get`


# Documentation
