module CodeRay
	module Encoders

	class HTML
		
		# This module is included in the output String from thew HTML Encoder.
		#
		# It provides methods like wrap, div, page etc.
		#
		# Remember to use #clone instead of #dup to keep the modules the object was
		# extended with.
		#
		# TODO: more doc.
		module Output

			require 'coderay/encoders/helpers/html_numerization.rb'

			attr_accessor :wrapped_in
			
			class << self
				
				# This makes Output look like a class.
				#
				# Example:
				# 
				#  a = Output.new '<span class="co">Code</span>'
				#  a.wrap! :page
				def new string, element = nil
					output = string.clone.extend self
					output.wrapped_in = element
					output
				end
				
				# Raises an exception if an object that doesn't respond to to_str is extended by Output,
				# to prevent users from misuse. Use Module#remove_method to disable.
				def extended o
					warn "The Output module is intended to extend instances of String, not #{o.class}." unless o.respond_to? :to_str
				end

				def stylesheet in_tag = false
					ss = CSS::DEFAULT_STYLESHEET
					ss = <<-CSS if in_tag
<style type="text/css">
#{ss}
</style>
					CSS
					ss
				end

				def page_template_for_css css = :default
					css = stylesheet if css == :default
					PAGE.apply 'CSS', css
				end

				# Define a new wrapper. This is meta programming.
				def wrapper *wrappers
					wrappers.each do |wrapper|
						define_method wrapper do |*args|
							wrap wrapper, *args
						end
						define_method "#{wrapper}!".to_sym do |*args|  
							wrap! wrapper, *args
						end
					end
				end
			end

			wrapper :div, :span, :page

			def wrapped_in? element
				wrapped_in == element
			end
			
			def wrap_in template
				clone.wrap_in! template
			end

			def wrap_in! template
				Template.wrap! self, template, 'CONTENT'
				self
			end
			
			def wrap! element, *args
				return self if not element or element == wrapped_in
				case element
				when :div
					raise "Can't wrap %p in %p" % [wrapped_in, element] unless wrapped_in? nil
					wrap_in! DIV
				when :span
					raise "Can't wrap %p in %p" % [wrapped_in, element] unless wrapped_in? nil
					wrap_in! SPAN
				when :page
					wrap! :div if wrapped_in? nil
					raise "Can't wrap %p in %p" % [wrapped_in, element] unless wrapped_in? :div
					wrap_in! Output.page_template_for_css
				when nil
					return self
				else
					raise "Unknown value %p for :wrap" % element
				end
				@wrapped_in = element
				self
			end

			def wrap *args
				clone.wrap!(*args)
			end

			def stylesheet in_tag = false
				Output.stylesheet in_tag
			end

			class Template < String

				def self.wrap! str, template, target
					target = Regexp.new(Regexp.escape("<%#{target}%>"))
					if template =~ target
						str[0,0] = $`
						str << $'
					else
						raise "Template target <%%%p%%> not found" % target
					end
				end
				
				def apply target, replacement
					target = Regexp.new(Regexp.escape("<%#{target}%>"))
					if self =~ target
						Template.new($` + replacement + $')
					else
						raise "Template target <%%%p%%> not found" % target
					end
				end

				module Simple
					def ` str  #`
						Template.new str
					end
				end
			end
			
			extend Template::Simple

#-- don't include the templates in docu
			
			SPAN = `<span class="CodeRay"><%CONTENT%></span>`

			DIV = <<-`DIV`
<div class="CodeRay">
	<div class="code"><pre><%CONTENT%></pre></div>	
</div>
			DIV

			TABLE = <<-`TABLE`
<table class="CodeRay"> <tr>
	<td class="line_numbers" title="click to toggle" onclick="with (this.firstChild.style) { display = (display == '') ? 'none' : '' }"><pre><%LINE_NUMBERS%></pre></td>
	<td class="code"><pre ondblclick="with (this.style) { overflow = (overflow == 'auto' || overflow == '') ? 'visible' : 'auto' }"><%CONTENT%></pre></td>
</tr> </table>
			TABLE
			# title="double click to expand" 

			LIST = <<-`LIST`
<ol class="CodeRay"><%CONTENT%></ol>
			LIST

			PAGE = <<-`PAGE`
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="de">
<head>
	<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
	<title>CodeRay HTML Encoder Example</title>
	<style type="text/css">
<%CSS%>
	</style>
</head>
<body style="background-color: white;">

<%CONTENT%>
</body>
</html>
			PAGE

		end

	end

end
end
