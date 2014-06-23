<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

  <title>misc/emacs/go-mode-load.el - The Go Programming Language</title>

<link type="text/css" rel="stylesheet" href="/lib/godoc/style.css">

<link rel="search" type="application/opensearchdescription+xml" title="godoc" href="/opensearch.xml" />

<script type="text/javascript">window.initFuncs = [];</script>
</head>
<body>

<div id="topbar" class="wide"><div class="container">

<form method="GET" action="/search">
<div id="menu">
<a href="/doc/">Documents</a>
<a href="/pkg/">Packages</a>
<a href="/project/">The Project</a>
<a href="/help/">Help</a>
<a href="/blog/">Blog</a>

<input type="text" id="search" name="q" class="inactive" value="Search" placeholder="Search">
</div>
<div id="heading"><a href="/">The Go Programming Language</a></div>
</form>

</div></div>



<div id="page" class="wide">
<div class="container">


  <div id="plusone"><g:plusone size="small" annotation="none"></g:plusone></div>
  <h1>Text file misc/emacs/go-mode-load.el</h1>




<div id="nav"></div>


<pre><span id="L1" class="ln">     1</span>	;;; go-mode-load.el --- automatically extracted autoloads
<span id="L2" class="ln">     2</span>	;;; Commentary:
<span id="L3" class="ln">     3</span>	
<span id="L4" class="ln">     4</span>	;; To install go-mode, add the following lines to your .emacs file:
<span id="L5" class="ln">     5</span>	;;   (add-to-list &#39;load-path &#34;PATH CONTAINING go-mode-load.el&#34; t)
<span id="L6" class="ln">     6</span>	;;   (require &#39;go-mode-load)
<span id="L7" class="ln">     7</span>	;;
<span id="L8" class="ln">     8</span>	;; After this, go-mode will be used for files ending in &#39;.go&#39;.
<span id="L9" class="ln">     9</span>	;;
<span id="L10" class="ln">    10</span>	;; To compile go-mode from the command line, run the following
<span id="L11" class="ln">    11</span>	;;   emacs -batch -f batch-byte-compile go-mode.el
<span id="L12" class="ln">    12</span>	;;
<span id="L13" class="ln">    13</span>	;; See go-mode.el for documentation.
<span id="L14" class="ln">    14</span>	;;
<span id="L15" class="ln">    15</span>	;; To update this file, evaluate the following form
<span id="L16" class="ln">    16</span>	;;   (let ((generated-autoload-file buffer-file-name)) (update-file-autoloads &#34;go-mode.el&#34;))
<span id="L17" class="ln">    17</span>	
<span id="L18" class="ln">    18</span>	;;; Code:
<span id="L19" class="ln">    19</span>	
<span id="L20" class="ln">    20</span>	
<span id="L21" class="ln">    21</span>	;;;### (autoloads (go-download-play godoc gofmt-before-save go-mode)
<span id="L22" class="ln">    22</span>	;;;;;;  &#34;go-mode&#34; &#34;go-mode.el&#34; (20767 50749))
<span id="L23" class="ln">    23</span>	;;; Generated autoloads from go-mode.el
<span id="L24" class="ln">    24</span>	
<span id="L25" class="ln">    25</span>	(autoload &#39;go-mode &#34;go-mode&#34; &#34;\
<span id="L26" class="ln">    26</span>	Major mode for editing Go source text.
<span id="L27" class="ln">    27</span>	
<span id="L28" class="ln">    28</span>	This mode provides (not just) basic editing capabilities for
<span id="L29" class="ln">    29</span>	working with Go code. It offers almost complete syntax
<span id="L30" class="ln">    30</span>	highlighting, indentation that is almost identical to gofmt,
<span id="L31" class="ln">    31</span>	proper parsing of the buffer content to allow features such as
<span id="L32" class="ln">    32</span>	navigation by function, manipulation of comments or detection of
<span id="L33" class="ln">    33</span>	strings.
<span id="L34" class="ln">    34</span>	
<span id="L35" class="ln">    35</span>	Additionally to these core features, it offers various features to
<span id="L36" class="ln">    36</span>	help with writing Go code. You can directly run buffer content
<span id="L37" class="ln">    37</span>	through gofmt, read godoc documentation from within Emacs, modify
<span id="L38" class="ln">    38</span>	and clean up the list of package imports or interact with the
<span id="L39" class="ln">    39</span>	Playground (uploading and downloading pastes).
<span id="L40" class="ln">    40</span>	
<span id="L41" class="ln">    41</span>	The following extra functions are defined:
<span id="L42" class="ln">    42</span>	
<span id="L43" class="ln">    43</span>	- `gofmt&#39;
<span id="L44" class="ln">    44</span>	- `godoc&#39;
<span id="L45" class="ln">    45</span>	- `go-import-add&#39;
<span id="L46" class="ln">    46</span>	- `go-remove-unused-imports&#39;
<span id="L47" class="ln">    47</span>	- `go-goto-imports&#39;
<span id="L48" class="ln">    48</span>	- `go-play-buffer&#39; and `go-play-region&#39;
<span id="L49" class="ln">    49</span>	- `go-download-play&#39;
<span id="L50" class="ln">    50</span>	
<span id="L51" class="ln">    51</span>	If you want to automatically run `gofmt&#39; before saving a file,
<span id="L52" class="ln">    52</span>	add the following hook to your emacs configuration:
<span id="L53" class="ln">    53</span>	
<span id="L54" class="ln">    54</span>	\(add-hook &#39;before-save-hook &#39;gofmt-before-save)
<span id="L55" class="ln">    55</span>	
<span id="L56" class="ln">    56</span>	If you&#39;re looking for even more integration with Go, namely
<span id="L57" class="ln">    57</span>	on-the-fly syntax checking, auto-completion and snippets, it is
<span id="L58" class="ln">    58</span>	recommended to look at goflymake
<span id="L59" class="ln">    59</span>	\(https://github.com/dougm/goflymake), gocode
<span id="L60" class="ln">    60</span>	\(https://github.com/nsf/gocode) and yasnippet-go
<span id="L61" class="ln">    61</span>	\(https://github.com/dominikh/yasnippet-go)
<span id="L62" class="ln">    62</span>	
<span id="L63" class="ln">    63</span>	\(fn)&#34; t nil)
<span id="L64" class="ln">    64</span>	
<span id="L65" class="ln">    65</span>	(add-to-list &#39;auto-mode-alist (cons &#34;\\.go\\&#39;&#34; &#39;go-mode))
<span id="L66" class="ln">    66</span>	
<span id="L67" class="ln">    67</span>	(autoload &#39;gofmt-before-save &#34;go-mode&#34; &#34;\
<span id="L68" class="ln">    68</span>	Add this to .emacs to run gofmt on the current buffer when saving:
<span id="L69" class="ln">    69</span>	 (add-hook &#39;before-save-hook &#39;gofmt-before-save).
<span id="L70" class="ln">    70</span>	
<span id="L71" class="ln">    71</span>	Note that this will cause go-mode to get loaded the first time
<span id="L72" class="ln">    72</span>	you save any file, kind of defeating the point of autoloading.
<span id="L73" class="ln">    73</span>	
<span id="L74" class="ln">    74</span>	\(fn)&#34; t nil)
<span id="L75" class="ln">    75</span>	
<span id="L76" class="ln">    76</span>	(autoload &#39;godoc &#34;go-mode&#34; &#34;\
<span id="L77" class="ln">    77</span>	Show go documentation for a query, much like M-x man.
<span id="L78" class="ln">    78</span>	
<span id="L79" class="ln">    79</span>	\(fn QUERY)&#34; t nil)
<span id="L80" class="ln">    80</span>	
<span id="L81" class="ln">    81</span>	(autoload &#39;go-download-play &#34;go-mode&#34; &#34;\
<span id="L82" class="ln">    82</span>	Downloads a paste from the playground and inserts it in a Go
<span id="L83" class="ln">    83</span>	buffer. Tries to look for a URL at point.
<span id="L84" class="ln">    84</span>	
<span id="L85" class="ln">    85</span>	\(fn URL)&#34; t nil)
<span id="L86" class="ln">    86</span>	
<span id="L87" class="ln">    87</span>	;;;***
<span id="L88" class="ln">    88</span>	
<span id="L89" class="ln">    89</span>	(provide &#39;go-mode-load)
<span id="L90" class="ln">    90</span>	;; Local Variables:
<span id="L91" class="ln">    91</span>	;; version-control: never
<span id="L92" class="ln">    92</span>	;; no-byte-compile: t
<span id="L93" class="ln">    93</span>	;; no-update-autoloads: t
<span id="L94" class="ln">    94</span>	;; coding: utf-8
<span id="L95" class="ln">    95</span>	;; End:
<span id="L96" class="ln">    96</span>	;;; go-mode-load.el ends here
</pre><p><a href="/misc/emacs/go-mode-load.el?m=text">View as plain text</a></p>

<div id="footer">
Build version devel +e081962da65c Mon Nov 04 12:35:11 2013 -0500.<br>
Except as <a href="http://code.google.com/policies.html#restrictions">noted</a>,
the content of this page is licensed under the
Creative Commons Attribution 3.0 License,
and code is licensed under a <a href="/LICENSE">BSD license</a>.<br>
<a href="/doc/tos.html">Terms of Service</a> | 
<a href="http://www.google.com/intl/en/policies/privacy/">Privacy Policy</a>
</div>

</div><!-- .container -->
</div><!-- #page -->

<script type="text/javascript" src="/lib/godoc/jquery.js"></script>

<script type="text/javascript" src="/lib/godoc/godocs.js"></script>

</body>
</html>

