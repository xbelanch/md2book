# md2book

**md2book** is a straightforward Ruby script designed to convert a markdown file into a self-zipped [Moodle book](https://docs.moodle.org/402/en/Book_resource) resource, which is then ready for upload.

To use this tool, you must have [Ruby](https://www.ruby-lang.org/en/) language programming and [Pandoc](https://pandoc.org/) installed on your system. It should work seamlessly on any GNU/Linux distribution, as well as on WSL2 and MacOS (though I haven't had the opportunity to test it extensively on the latter).

If you encounter any issues while using **md2book**, please don't hesitate to open a ticket so that I can investigate further.

I'd also like to extend my gratitude to [Huub de Beer](https://github.com/htdebeer), developer of [Paru](https://github.com/htdebeer/paru) and [Pandocomatic](https://github.com/htdebeer/pandocomatic), as their contributions have made the development process smoother and more efficient.

## Quick example

Follow these steps to see how it works:

1. Ensure that you have Ruby installed on your system. You can confirm this by running the command `ruby -v` in your terminal.
2. Clone or download the code repository to a local directory on your machine.
3. Navigate to the root directory of the project in your terminal and run the following command to install all the necessary gem dependencies:

    ``` shell
    $ bundle install
    ```

4. Once the dependencies are installed, run the example by executing the following command:

    ``` shell
    $ bundle exec ruby md2book.rb example/book.md
    ```

This will generate a Moodle book resource in *zip* format based on the contents of the `example/book.md` file. You can modify the content of this file or provide your own Markdown file to generate a different book.

If you encounter any errors during the installation or execution process, make sure to check the error messages for hints on how to resolve them.

Please remember to provide the *_data_dir* folder, which not only contains the template files (html and css) but also the `moodlebook.rb` filter required for proper functionality.

## Can you provide a dockerized version?

It is possible that this may be considered in the future.
