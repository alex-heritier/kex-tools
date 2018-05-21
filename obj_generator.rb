#!/Users/alex/.rvm/rubies/ruby-2.5.1/bin/ruby

require 'rubygems'
require 'json'

PACKAGE_LINE = "package com.kashin.bo;"

puts "Kashin KObject Generator";

# Get template file
template_filename = ARGV[0]
exit if template_filename.nil?

puts "Loading template file #{template_filename}..."

# Parse template file
template_file = File.read(template_filename)
json = JSON.parse(template_file)


# Verify json
name = json["name"].strip
fields = json["fields"].map {|field| field.strip }
exit if name.nil? || fields.nil?

puts "Building kobject file..."

# Build kobject
## Build header
kobj_buffer = %Q{\
#{PACKAGE_LINE}

import org.json.JSONObject;

public class #{name} extends KObject \{
}

# Upcase special field names
fields.each do |field|
  field.upcase! if field == "kuid" || field == "buid"
end

def as_private str
  str = str.gsub(/\ ([a-zA-Z])/) {|word| word.strip.upcase} # upcase letters after spaces
  str.gsub(/\ ([0-9])/) {|word| word.strip} # remove space before numbers
end

## Build statics
def as_static str
  str.upcase.gsub(' ', '_')
end

fields.each do |field|
  static_field = as_static field
  var_name = as_private field.downcase
  kobj_buffer << "\tpublic static final String #{static_field} = \"#{var_name}\";\n"
end
kobj_buffer << "\n"

## Build private vars
fields.each do |field|
  private_field = as_private field.downcase
  kobj_buffer << "\tprivate String #{private_field};\n"
end
kobj_buffer << "\n"

## Build setters and getters
fields.each do |field|
  # Build getter
  getter_method_name = as_private("get " + field)
  var_name = as_private field.downcase
  kobj_buffer << "\tpublic String #{getter_method_name}() { return #{var_name}; }\n"

  # Build setter
  setter_method_name = as_private("set " + field)
  kobj_buffer << "\tpublic void #{setter_method_name}(String z) { this.#{var_name} = z; }\n"
  kobj_buffer << "\n"
end

## Build toJSON
kobj_buffer << "\tpublic JSONObject toJSON() {\n"
kobj_buffer << "\t\tJSONObject jsonOut = new JSONObject();\n"
kobj_buffer << "\n"
fields.each do |field|
  static_name = as_static field
  var_name = as_private field.downcase
  kobj_buffer << "\t\tjsonOut.put(#{static_name}, #{var_name});\n"
end
kobj_buffer << "\n"
kobj_buffer << "\t\treturn jsonOut;\n"
kobj_buffer << "\t}\n"

kobj_buffer << "}"

# Replace all tabs with spaces
kobj_buffer.gsub!("\t", '    ')

# Replace all 'Id's with 'ID'
kobj_buffer.gsub!(/Id[^a-zA-Z]/) {|snippet| snippet[1] = 'D'; snippet }

# Replace all 'Kuid's with 'KUID'
kobj_buffer.gsub!(/(?=[a-zA-Z])Kuid/) {|snippet| snippet.upcase }

File.open("#{name}.java", 'w') { |file| file.write(kobj_buffer) }

puts "Done!"
