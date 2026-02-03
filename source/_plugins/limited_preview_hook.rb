Jekyll::Hooks.register :site, :pre_render do |site|
  if site.config['preview'].instance_of?(Array) && site.config['preview'].length.positive?
    included_pages = %r{^/?(#{site.config['preview'].join('|')})} # Preview prefixes can have a leading slash or not.
    puts "full site has #{site.pages.length} pages"
    site.pages.delete_if do |page|
      !(page.url =~ included_pages)
    end
    puts "finished dropping pages, preview site has #{site.pages.length} pages"
  end
end
