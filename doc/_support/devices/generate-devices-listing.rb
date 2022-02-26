require "erb"
require "json"

def githubURL(device)
  "https://github.com/Tow-Boot/Tow-Boot/tree/released/boards/#{device}"
end

def yesno(bool)
  if bool
    "yes"
  else
    "no"
  end
end

NOTES_HEADER = "## Device-specific notes"

COLUMNS = [
  { key: "device.identifier",   name: "Identifier" },
  { key: "device.name",         name: "Name" },
  { key: "hardware.soc",        name: "SoC" },
]

$out = ENV["out"]
$devicesInfo = Dir.glob(File.join(ENV["devicesInfo"], "*")).sort.map do |filename|
  data = JSON.parse(File.read(filename))
  [data["device"]["identifier"], data]
end.to_h
$devicesDir = ENV["devicesDir"]

# First, generate the devices listing.
puts ":: Generating devices/index.md"
File.open(File.join($out, "devices/index.md"), "w") do |file|
  file.puts <<~EOF
  Devices List
  ============

  The following table lists all devices supported by the latest release of
  Tow-Boot.

  <div class="devices-list">

  EOF

  lastManufacturer = nil
  $devicesInfo.keys.sort.each do |identifier|
    data = $devicesInfo[identifier]
    if $lastManufacturer != data["device"]["manufacturer"]

      unless $lastManufacturer == nil
        # Close `responsive-table` from the last manufacturer
        file.puts <<~EOF
          </div>
        EOF
      end

      $lastManufacturer = data["device"]["manufacturer"]

      file.puts <<~EOF

      ## #{data["device"]["manufacturer"]}

      <div class="responsive-table">

      |#{COLUMNS.map {|col| " #{col[:name]               } |" }.join("")}
      |#{COLUMNS.map {|col| " #{col[:name].gsub(/./, "-")} |" }.join("")}
      EOF

    end
    file.print("|")
    COLUMNS.each do |col|
      value = data.dig(*(col[:key].split(".")))
      if col[:key] == "device.identifier"
        file.print(" [`#{value}`](devices/#{identifier}.md) |")
      else
        file.print(" [#{value}](devices/#{identifier}.md) |")
      end
    end
    file.puts("")
  end

  file.puts <<~EOF

    </div>
  </div>

  EOF
end

# Then generate per-device pages
$devicesInfo.values.each do |info|
  identifier = info["device"]["identifier"]
  puts ":: Generating devices/#{identifier}.md"
  File.open(File.join($out, "devices/#{identifier}.md"), "w") do |file|
    file.puts <<~EOF

    <section class="device-sidebar">

      # #{info["device"]["fullName"]}

      <dl>
        <dt>Manufacturer</dt>
          <dd>#{info["device"]["manufacturer"]}</dd>
        <dt>Name</dt>
          <dd>#{info["device"]["name"]}</dd>
        <dt>Identifier</dt>
          <dd>#{info["device"]["identifier"]}</dd>
        <dt>SoC</dt>
          <dd>#{info["hardware"]["soc"]}</dd>
        <dt>Dedicated firmware storage</dt>
          <dd>#{yesno(info["hardware"]["withSPI"] || info["hardware"]["withMMCBoot"])}</dd>
        <dt>Architecture</dt>
          <dd>#{info["system"]["system"]}</dd>
        <dt>Source</dt>
          <dd><a href="#{githubURL(identifier)}">Tow-Boot repository</a></dd>
      </dl>
    </section>

    EOF

    file.puts(info["documentation"]["installationInstructions"])

    # Generate the page contents

    #template = ERB.new(File.read(info["documentation"]["systemTypeFargment"]))
    #file.puts(template.result(binding))

    # Ensure the content is at least separated by an empty line.
    # Otherwise a trailing command could end-up being merged.
    file.puts("\n\n")
    
    deviceNotesFile = File.join($devicesDir, identifier, "README.md")
    if File.exists?(deviceNotesFile)
      first_line, notes = File.read(deviceNotesFile).split("\n", 2)
      first_line.strip!
      notes.strip!

      first_notes_line = notes.lines.first.strip
      expected_header = "# #{info["device"]["fullName"]}"
      unless first_line == expected_header
        $stderr.puts(
          "Unexpected first line for %s." % [ identifier ],
          "\tGot:      #{first_line.inspect}",
          "\tExpected: #{expected_header.inspect}",
        )
        exit 1
      end
      unless first_notes_line == NOTES_HEADER
        $stderr.puts(
          "Unexpected device-specific notes header for %s." % [ identifier ],
          "\tGot:      #{first_line.inspect}",
          "\tExpected: #{NOTES_HEADER.inspect}",
        )
        exit 1
      end
      file.puts(notes)
    else
      file.puts(NOTES_HEADER)
      file.puts("\n_(No device-specific notes available)_\n\n")
    end
  end
end
