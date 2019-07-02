# Passman CLI Password Manager

This only works for Mac OSX.

## Commands:

`passman`

Will include an interactive password management interface which allows for creation, deletion, updating, and removing passwords. This CLI includes clipboard usage.

`passman -f file_name.txt`

This command will import the specified file into the password manager, the layout of the file is specified in the Bulk Entry section.

`passman site_i_want_to_search`

This command allows for a quick retrieval of the password for a specific site. I

## Bulk Entry:

The layout for the text file is:

```
site: example site
user: my@user.com
pass: mypassword
tags: individual tags separated by spaces
note: security question 1;security question 2

site: example site
user: myotheruser
pass: mysupersecretpassword
tags: individual tags separated by spaces
note: security question 1;security question 2

```

Once the text is formatted you will be able to import it with:

```
passman -f [your file name]
```

Make sure to delete the text file with your passwords when the imports are completed.
