[delimport](http://ianhenderson.org/delimport.html) is a bookmark importer for old-school delicious and all pinboard accounts. It downloads your stored bookmarks to your Mac’s hard drive and adds them to the Spotlight index.

Originally developed by [Ian Henderson](http://ianhenderson.org/), with most changes since version 0.3 by [Sven-S. Porst](http://earthlingsoft.net/ssp/).


### TODO
* Handle redirects?
** e.g. http://www.guardian.co.uk/comment/story/0,3604,1326603,00.html
* allow multiple bookmarking accounts
* Login item with helper app
* show/hide Dock icon
* Sparkle?
* Use keychain to download password protected pages?


### History
<dl>
<dt>v0.7, upcoming / brave-new-world branch</dt>
<dd>
<ul>
<li>Save webarchives for the bookmarked URLs.</li>
<li>X.7 and above only.</li>
<li>ARC</li>
<li>sandboxed</li>
<li>Remove Keychain.framework, use SSKeychain instead</li>
<li>Fetch bookmarks in batches of 1000 (new delicious does not send more in one go)</li>
<li>Proper icon for pinboard courtesy of Nicolas Baumüller</li>
</ul>
</dd>

<dt>v0.6, 2011/2012 <a href="http://earthlingsoft.net/beta/delimport0.6.zip">download</a></dt>
<dd>
<ul>
<li>Officially be X.5 only and garbage collected.</li>
<li>Implement queue for webarchive downloading.</li>
<li>Hold option key at launch to see settings window.</li>
<li>Add timeout for downloads to cancel them.</li>
<li>Fix crashes during web archive downloads (thanks Mike!).</li>
<li>Store Bookmarks and errors in Application Support folder.</li>
</ul>

<dt>v0.5, 2011-04 (<a href="http://earthlingsoft.net/beta/delimport0.5.zip">download</a>)</dt>
<dd>
<ul>
<li>
Use Pinboard URLs.
</li>
</ul>
</dd>

<dt>v0.4, 2009-09</dt>
<dd>
<ul>
<li>
Add 64bit binaries (comes with a current version of the Keychain framework to make that work).
</li><li>
Support Sudden Termination on X.6.
</li><li>
Add German localisation.
</li><li>
Add French localisation (thanks to Ronald Leroux).
</li><li>
Change bookmark format to actually conform to that of Safari’s bookmarks as claimed by our UTI.
</li><li>
Check whether all bookmarks are present on launch and re-create them if necessary.
</li><li>
Add ability to not show 'Add to Login Items' dialogue again on X.5 and above.
</li>
</ul>
</dd>

<dt>v0.3, released 5th December 2007</dt>
<dd>
No more installer, supports Leopard, runs on x86, makes waffles – thanks Sven! - <a href="http://ianhenderson.org/download/delimport.zip">Download</a> (381 KB)
</dd>

<dt>v0.2, released 14th August 2006</dt>
<dd>
Supports new del.icio.us API – please upgrade if you are still running version 0.1.2 - <a href="http://ianhenderson.org/download/delimport%200.2.dmg">Download</a> (454 KB)
</dd>
