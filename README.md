Ad Scrubber
===========
Ad Scrubber is an open-source content filtering application for Safari that blocks third-party scripts and more than 25,000 websites that have been identified as serving ads or malware.

#### Enabling Content Blockers

To enable content blocking: Settings > Safari > Content Blockers

#### Hardware Requirements

As an app that uses the Safari Content Blocker extension, older hardware is not supported. The hardware requirements for Ad Scrubber are:

- iPhone 6
- iPhone 6 Plus
- iPhone 5s
- iPad Air 2
- iPad Air
- iPad mini 2
- iPad mini 3
- iPod touch 6

### Custom Rules

Ad Scrubber can also be used as a platform for implementing custom content-filtering rules. The application is written in Swift as a ContentBlocker Extension and supports custom content-blocking lists in either of two formats: hosts file format or WebKit Content Blocker JSON format.

#### Hosts files
Hosts files with lists of ad and malware-serving websites have long been used to optimize the browsing experience on laptops and desktops. Ad Scrubber leverages Safari's Content Blocker functionality to now allow use of such lists on Apple mobile devices. Ad Scrubber's built-in list comes from Steven Black's "amalgamated hosts file" at https://github.com/StevenBlack/hosts. When using hosts files (the built-in list or a downloaded hosts file), Ad Scrubber will always block third-party scripts. Note that when loading hosts files Safari may not implement very large rule sets.

#### Content Blocker JSON files
In addition to hosts files, Ad Scrubber can load rules in Content Blocker JSON format (see: https://webkit.org/blog/3476/content-blockers-first-look/). When Content Blocker rules are loaded by Ad Scrubber the rules are presented to Safari as they are received (i.e. no rule to block third-party scripts is added, as Ad Scrubber does with hosts files). Note that when loading Content Blocker rules, Safari may not implement very large or complex rule sets.
