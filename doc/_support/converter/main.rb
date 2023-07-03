#!/usr/bin/env ruby

require "erb"
require "fileutils"
require "nokogiri"
require "open3"
require "shellwords"

# {{{

class String
  def blank?
    self.match(/^\s+$/)
  end
end

class MarkdownDocument
  def initialize(contents)
    @contents = contents
  end

  def self.from_filename(filename)
    self.new(File.read(filename))
  end

  def to_html()
    @html ||= cmark("--to", "html")
    @html
  end

  def to_xml()
    @xml ||= Nokogiri::XML(cmark("--to", "xml"))
    @xml
  end

  # Returns the first h1-level heading
  def title()
    el = to_xml.at_css("heading[level=1] > text")
    raise "No level-1 heading in document." if el.nil? || el.text.blank?
    el.text
  end

  def cmark(*args)
    cmd = [
      "cmark-gfm",
      "--unsafe",
      "--extension", "table",
      "--extension", "autolink",
      *args
    ]
    output, err, status = Open3.capture3(*cmd, stdin_data: @contents)
    unless status.success?
      $stderr.puts(output)
      $stderr.puts(err)
      raise "Error running #{cmd.shelljoin}..."
    end

    output
  end
end

class SitePage
  def self.support_location=(value)
    @@support_location = value
  end

  def initialize(markdown_document, output_name)
    @markdown_document = markdown_document
    @output_name = output_name
  end

  # Use in `<base href="" />`.
  def document_base()
    File.dirname(@output_name).sub(/^\.$/, "").sub(%r{[^/]+}, "..")
  end

  def relative_output()
   @output_name.sub(%r{#{".md"}$}, ".html")
  end

  def output_name()
    File.join($output, relative_output)
  end

  # Use in `<title>` or anywhere else relevant.
  def title()
    @markdown_document.title()
  end

  # Use where the contents should be displayed.
  def contents()
    @markdown_document.to_html()
      .gsub(%r{href="([^"]+)\.md"}, %q{href="\\1.html"})
  end

  # Writes the HTML document to the given filename.
  def write()
    template = ERB.new(File.read(File.join(@@support_location, "template.erb")))
    file_contents = template.result(self.binding())
    File.write(output_name, file_contents)
  end
end

def generate_sitemap(sitemap)
  list = sitemap.sort{ |a, b| a.first <=> b.first }.map do |pair|
    filename, page = pair
    " | `#{filename}` | [#{page.title}](#{filename}) |"
  end

  # We don't have a hierarchy for subfolders.
  # So since this makes the sitemap unwieldy to use, we're using
  # a simple table with file path to clearly show what's where.
  document = [
    "# Site Map",
    "",
    "| path | page title |",
    "| ---- | ---------- |",
    list.join("\n"),
    "",
  ].join("\n")

  markdown_document = MarkdownDocument.new(document)

  page = SitePage.new(markdown_document, "sitemap.md")
  page.write()
end

# }}}

if ARGV.length < 2 then
  $stderr.puts "Usage: main.rb <source dir> <output dir>"
  exit 1
end

$source = ARGV.shift
$output = ARGV.shift

SitePage.support_location = File.join($source, "_support")

files = Dir.glob(File.join($source, "**/*.md"))

# Used to collect all pages
sitemap = []

files.each do |filename|
  relative_name = filename.sub(%r{^#{$source}}, "")
  $stderr.puts "\n⇒ processing #{relative_name}"

  markdown_document = MarkdownDocument.from_filename(filename)
  page = SitePage.new(markdown_document, relative_name)
  FileUtils.mkdir_p(File.dirname(page.output_name))
  page.write()
  sitemap << [page.relative_output, page]
end

generate_sitemap(sitemap)

$stderr.puts("\n\n\nDone!\n\n")
