## Strings & Localization

Translations are hosted by [Transifex](https://www.transifex.com/projects/p/chatsecure/)

### Adding a new string

* Open `strings.json` in your favorite editor.
* Add a new dictionary to the array with the following format:
	* Name of String in all caps with underscores (this will be the name used in XCode).
	* Add the string with the key `string`.
	* Add a comment that describes how the string is used with the key `comment`
* Run `StringsConverter.py` (requires Python 2.7+)

```
$ python3 ./OTRAssets/Strings/StringsConverter.py
```

### Setting up Transifex (only if you've been granted access to our Tranifex project)

* [Install Transifex](http://support.transifex.com/customer/portal/articles/995605-installation)
* [Configure the Client](http://support.transifex.com/customer/portal/articles/1000855-configuring-the-client)

### Pushing new English strings to Transifex

* Make sure to build project in Xcode. This creates or updates the `localizable.strings` from `strings.json` that will be uploaded.
* `$ tx push -s`

### Pulling translations from Transifex

* `$ tx pull -a`

### Finding Unused Strings

StringsUnused.py requires Python 3.6 or higher.

```
$  python3 ./OTRAssets/Strings/StringsUnused.py ./ChatSecure/Classes/ ./ChatSecureCore/ ./OTRAssets/
```