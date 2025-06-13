# Grouping Project

See the [INSTRUCTIONS.md][instructions] for an overview of the project requirements.

## Thought Process

I've built a number of ETL scripts over the years, and they each have similarities. I always start from the expectation
that each line is a record that will be referenced, and some sort of transformation or data analysis will be
necessary. 

So, my initial thought process was to use a keyed Hash for tracking data ownership, and the record's owner id, which
was a great place to start. Using these ideas, I created the [CsvHandler][csv handler] and started fleshing it out.
It wasn't long before I started to see other classes in the code. 

As I shifted into that mind space, I realized I needed to flesh out the project, and I opted to use my
[Booster Pack][booster pack] project to scaffold together  autoloading, spec support, and `bin/` setup. Once I did that,
I also copied the [provided instructions][instructions] into the project, and copied the provided input files as
fixtures, so I could write specs that would include them.

First, I identified the need for a standalone module that could normalize data, which became the
[DataNormalizer][data normalizer] module. Its job is very straight-forward, take an email address or phone number, and
transform it into a standardized format.

Next, it was clear that tracking data and its owner could get messy, and really didn't seem to belong entirely in what
was becoming the primary class for the project. So, I took that logic and extracted it into the
[IdGenerator][id generator], and after writing specs for it, I was very happy with how it tracked the data using a keyed
hash, generated unique ids for owners, and returned existing ids for matching data.

I then spent some time thinking about performance, and instead of traversing the input file or its data multiple times,
I decided to have it write data directly after identifying which id owned the email and/or phone. This also helped
reduce memory usage, as there was no longer a reason to keep the entire input file in a variable, only the current
record. 

After examining what was now running faster and more efficiently, the last piece that seemed completely
out-of-place was the [MatchType][match type] class that I would soon I extract. This helped create a single object that
can be used to identify which data should be matched on, and which particular fields to find that data in.

When I suspect it was ready to be refactored and wrapped up, I discovered that the class I had been working in *did*, in
fact contain a class that should be extracted. I was in the then-named PersonMatcher, and while I had suspected I would
be extracting the CSV handling aspects, I was surprised to find that instead, it was the [PersonMatcher][person matcher].
The matching logic just didn't belong, it was difficult to isolate and test, and after struggling with failing specs, I
decided to sleep on it. I let my brain run wild with it, and I woke up with the extracted class sitting fully formed
in my mind, just waiting to be typed out.

## Design

There are four major classes, [CsvHandler][csv handler], [PersonMatcher][person matcher], [MatchType][match type], and
[IdGenerator][id generator], as well as one module, [DataNormalizer][data normalizer].

### CsvHandler

Performs validation on both input file access and on the passed-in match type, walking through the input file, and
calling the `PersonMatcher` on each record, and writing the returned values to the output file.

### PersonMatcher

Performs the record matching checks, using the `DataNormalizer` for formatting the respective data, the `IdGenerator`
for in-memory access of previously generated ids and the generation of new ones, and the `MatchType` class to understand
which fields to check and which logic to use for the matching algorithm.

### DataNormalizer

In charge of formatting email address and phone numbers in standardized formats (`lowercase-no-whitespaces@email.com` and
`555-555-5555`, respectively).

### IdGenerator

Tracks which email address and phone number data has been seen. When asked to track string data it has not yet seen, it
increases the iterator it uses to track the number of elements in the associated hash, prepends the desired prefix
(`person` in our case), caches that data, and returns the new id (example: `person42`).

### MatchType

Answers very simple questions about the provided type to match on, are we matching on the email address? Are we matching
on the phone number? In cases where the desired type to match on is `email_or_phone`, both of these questions will
respond with `true`. Having the answer to these questions, as well as the header fields for the input CSV, it also
provides the answer to what the `email_header` and `phone_header` fields are.

## Design Diagram

```text
+---------------------------+    +-----------------+    +--------------------------------+                    
| bin/match_records         |    | PersonMatcher   |    | DataNormalizer                 |                    
|                           |    |                 |<-->|                                |                    
| Handles data input and    |    | Performs the    |    | Standardizes match data        |                    
| output display            |    | desired         |    +--------------------------------+                    
+---------------------------+    | record matching |    +--------------------------------+                    
            ^                    | algorithm       |    | IdGenerator                    |                    
            |                    |                 |<-->|                                |                    
            v                    |                 |    | Tracks data ownership and ids  |                    
+---------------------------+    |                 |    +--------------------------------+                    
| CsvHandler                |    |                 |    +--------------------------------+                    
|                           |    |                 |    | MatchType                      |                    
|Handles input validation,  |<-->|                 |<-->|                                |                    
|data parsing and exporting |    |                 |    | Knows which fields to match on |                    
+---------------------------+    +-----------------+    +--------------------------------+ 
```

## Matching Algorithm

From the [INSTRUCTIONS.md][instructions]

> A matching type is a declaration of what logic should be used to compare the rows.
>
> For example: A matching type named same_email might make use of an algorithm that
> matches rows based on email columns.

After discussing matching criteria with the user, I decided to match on the primary phone and email, as secondary values
were often associated with other records that could be considered family members.

Matching is normalized data being checked against a dictionary of normalized data that has already been catalogued. At
the lowest level, it is two strings being compared to check for equality.

### Match Types

#### `email`

Utilizes the primary email address field (`Email` or `Email1`, or `Email` in the case that both exist as headers) for
data normalizing and matching.

#### `phone`

Utilizes the primary phone number field (`Phone` or `Phone1`, or `Phone` in the case that both exist as headers) for
data normalizing and matching.

#### `email`, `phone`, and `email_or_phone`

Performs the `email` match type first, followed by the `phone` match type when the former does not have an owner.

## Tradeoffs

### CSV Parser

Ruby does have a CSV parser in its standard library, but with performance being a primary
concern, I opted to write a leaner version to fit the specific need, which can more easily be optimized (when necessary).

### Record Matching

I thought about using a database to help assist with the finding matches. I also considered using known, big-data style
algorithms. However, key-value storage can be very quick, and with 20,000 records being the largest set of input data,
it is efficient without needing extra resources. This may be a concern as the file sizes grow, as lookups will become more
costly.

## Code Organization

* `bin/` is where I placed executable scripts, namely `parse` and `setup`.
* `config/` is for initializing the autoloader, setting the environment, and loading Bundler.
* `lib/` is for project-based code, and it's where I placed all four classes and the module I wrote.
* `spec/` is for everything test-related. The RSpec `spec_helper.rb` file, fixture files, support files, and most importantly, the tests for the project classes.

## Project Structure

Uses my own [Booster Pack][booster pack] to expedite the project setup. This includes some elements
that I find core to being a production-ready application.

* Standardized layout (`bin/`, `config/`, `lib/`, `spec/`)
* Config files
    * Environment support
    * Bundler loading
    * Class autoloading with `zeitwerk`
* RuboCop to standardize formatting
* RSpec setup (with a linter-based spec)
* Rakefile with a `spec` task
* SimpleCov for code coverage
* Ruby version support using both `Gemfile` and `.ruby-version`
* CI support through a GitHub workflow config
    * `.github/workflows/test.yml`
* `bin/` directory
    * `bin/setup`
    * `bin/console` to load a Pry-based console

## Usage

### Setting Up

Run `bin/setup` to get everything installed.

## Requirements

Ruby version 3.4 or higher.

### Parsing Data

Call `bin/match_records` and pass in the desired CSV file to be parsed, and the preferred match type to use.

```shell
$ bin/match_records --file spec/fixtures/input3.csv --match-type email_or_phone
Matching Type: email_or_phone
Input File:    /path/to/repo/spec/fixtures/input3.csv
Output File:   /path/to/repo/home/output/matched-email-or-phone-input3.csv

Processing... complete! (0.08655 sec)
```

It will use `optparse` to handle the passed flags and their values. Each file parsed will have its performance measured
using `Benchmark.realtime`.

It will then display which `Matching Type` was used, the `Input File` passed, and the `Output File` it exported the
input data and the new `OwnerId` field for each record.

## Help

The `bin/match_records` script utilizes the `optparse` library to help provided a standardized commandline interface.

```shell
bin/match_records --help

Usage: bin/match_records --file [FILENAME] --match-type [MATCH_TYPE]
    -f, --file FILENAME              CSV file to process
    -m, --match-type FIELD           Field to use for record identification (email, phone, email_or_phone)
    -h, --help                       Show this help
```

## Running RSpec Tests

To run the RSpec suite, use the following:

```shell
bundle exec rspec
```

## Viewing Code Coverage

After running the RSpec Suite, the code coverage can be viewed by opening [coverage/index.html][simplecov output] in
your web browser.

[instructions]: ./INSTRUCTIONS.md
[booster pack]: https://github.com/trueheart78/booster_pack
[simplecov output]: ./coverage/index.html
[data normalizer]: ./lib/data_normalizer.rb
[id generator]: ./lib/id_generator.rb
[match type]: ./lib/match_type.rb
[csv handler]: ./lib/csv_handler.rb
[person matcher]: ./lib/person_matcher.rb
[input2 fixture]: ./spec/fixtures/input2.csv
