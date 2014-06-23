<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

  <title>misc/emacs/go-mode.el - The Go Programming Language</title>

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
  <h1>Text file misc/emacs/go-mode.el</h1>




<div id="nav"></div>


<pre><span id="L1" class="ln">     1</span>	;;; go-mode.el --- Major mode for the Go programming language
<span id="L2" class="ln">     2</span>	
<span id="L3" class="ln">     3</span>	;; Copyright 2013 The Go Authors. All rights reserved.
<span id="L4" class="ln">     4</span>	;; Use of this source code is governed by a BSD-style
<span id="L5" class="ln">     5</span>	;; license that can be found in the LICENSE file.
<span id="L6" class="ln">     6</span>	
<span id="L7" class="ln">     7</span>	(require &#39;cl)
<span id="L8" class="ln">     8</span>	(require &#39;etags)
<span id="L9" class="ln">     9</span>	(require &#39;ffap)
<span id="L10" class="ln">    10</span>	(require &#39;find-file)
<span id="L11" class="ln">    11</span>	(require &#39;ring)
<span id="L12" class="ln">    12</span>	(require &#39;url)
<span id="L13" class="ln">    13</span>	
<span id="L14" class="ln">    14</span>	;; XEmacs compatibility guidelines
<span id="L15" class="ln">    15</span>	;; - Minimum required version of XEmacs: 21.5.32
<span id="L16" class="ln">    16</span>	;;   - Feature that cannot be backported: POSIX character classes in
<span id="L17" class="ln">    17</span>	;;     regular expressions
<span id="L18" class="ln">    18</span>	;;   - Functions that could be backported but won&#39;t because 21.5.32
<span id="L19" class="ln">    19</span>	;;     covers them: plenty.
<span id="L20" class="ln">    20</span>	;;   - Features that are still partly broken:
<span id="L21" class="ln">    21</span>	;;     - godef will not work correctly if multibyte characters are
<span id="L22" class="ln">    22</span>	;;       being used
<span id="L23" class="ln">    23</span>	;;     - Fontification will not handle unicode correctly
<span id="L24" class="ln">    24</span>	;;
<span id="L25" class="ln">    25</span>	;; - Do not use \_&lt; and \_&gt; regexp delimiters directly; use
<span id="L26" class="ln">    26</span>	;;   go--regexp-enclose-in-symbol
<span id="L27" class="ln">    27</span>	;;
<span id="L28" class="ln">    28</span>	;; - The character `_` must not be a symbol constituent but a
<span id="L29" class="ln">    29</span>	;;   character constituent
<span id="L30" class="ln">    30</span>	;;
<span id="L31" class="ln">    31</span>	;; - Do not use process-lines
<span id="L32" class="ln">    32</span>	;;
<span id="L33" class="ln">    33</span>	;; - Use go--old-completion-list-style when using a plain list as the
<span id="L34" class="ln">    34</span>	;;   collection for completing-read
<span id="L35" class="ln">    35</span>	;;
<span id="L36" class="ln">    36</span>	;; - Use go--kill-whole-line instead of kill-whole-line (called
<span id="L37" class="ln">    37</span>	;;   kill-entire-line in XEmacs)
<span id="L38" class="ln">    38</span>	;;
<span id="L39" class="ln">    39</span>	;; - Use go--position-bytes instead of position-bytes
<span id="L40" class="ln">    40</span>	(defmacro go--xemacs-p ()
<span id="L41" class="ln">    41</span>	  `(featurep &#39;xemacs))
<span id="L42" class="ln">    42</span>	
<span id="L43" class="ln">    43</span>	(defalias &#39;go--kill-whole-line
<span id="L44" class="ln">    44</span>	  (if (fboundp &#39;kill-whole-line)
<span id="L45" class="ln">    45</span>	      #&#39;kill-whole-line
<span id="L46" class="ln">    46</span>	    #&#39;kill-entire-line))
<span id="L47" class="ln">    47</span>	
<span id="L48" class="ln">    48</span>	;; Delete the current line without putting it in the kill-ring.
<span id="L49" class="ln">    49</span>	(defun go--delete-whole-line (&amp;optional arg)
<span id="L50" class="ln">    50</span>	  ;; Emacs uses both kill-region and kill-new, Xemacs only uses
<span id="L51" class="ln">    51</span>	  ;; kill-region. In both cases we turn them into operations that do
<span id="L52" class="ln">    52</span>	  ;; not modify the kill ring. This solution does depend on the
<span id="L53" class="ln">    53</span>	  ;; implementation of kill-line, but it&#39;s the only viable solution
<span id="L54" class="ln">    54</span>	  ;; that does not require to write kill-line from scratch.
<span id="L55" class="ln">    55</span>	  (flet ((kill-region (beg end)
<span id="L56" class="ln">    56</span>	                      (delete-region beg end))
<span id="L57" class="ln">    57</span>	         (kill-new (s) ()))
<span id="L58" class="ln">    58</span>	    (go--kill-whole-line arg)))
<span id="L59" class="ln">    59</span>	
<span id="L60" class="ln">    60</span>	;; declare-function is an empty macro that only byte-compile cares
<span id="L61" class="ln">    61</span>	;; about. Wrap in always false if to satisfy Emacsen without that
<span id="L62" class="ln">    62</span>	;; macro.
<span id="L63" class="ln">    63</span>	(if nil
<span id="L64" class="ln">    64</span>	    (declare-function go--position-bytes &#34;go-mode&#34; (point)))
<span id="L65" class="ln">    65</span>	
<span id="L66" class="ln">    66</span>	;; XEmacs unfortunately does not offer position-bytes. We can fall
<span id="L67" class="ln">    67</span>	;; back to just using (point), but it will be incorrect as soon as
<span id="L68" class="ln">    68</span>	;; multibyte characters are being used.
<span id="L69" class="ln">    69</span>	(if (fboundp &#39;position-bytes)
<span id="L70" class="ln">    70</span>	    (defalias &#39;go--position-bytes #&#39;position-bytes)
<span id="L71" class="ln">    71</span>	  (defun go--position-bytes (point) point))
<span id="L72" class="ln">    72</span>	
<span id="L73" class="ln">    73</span>	(defun go--old-completion-list-style (list)
<span id="L74" class="ln">    74</span>	  (mapcar (lambda (x) (cons x nil)) list))
<span id="L75" class="ln">    75</span>	
<span id="L76" class="ln">    76</span>	;; GNU Emacs 24 has prog-mode, older GNU Emacs and XEmacs do not, so
<span id="L77" class="ln">    77</span>	;; copy its definition for those.
<span id="L78" class="ln">    78</span>	(if (not (fboundp &#39;prog-mode))
<span id="L79" class="ln">    79</span>	    (define-derived-mode prog-mode fundamental-mode &#34;Prog&#34;
<span id="L80" class="ln">    80</span>	      &#34;Major mode for editing source code.&#34;
<span id="L81" class="ln">    81</span>	      (set (make-local-variable &#39;require-final-newline) mode-require-final-newline)
<span id="L82" class="ln">    82</span>	      (set (make-local-variable &#39;parse-sexp-ignore-comments) t)
<span id="L83" class="ln">    83</span>	      (setq bidi-paragraph-direction &#39;left-to-right)))
<span id="L84" class="ln">    84</span>	
<span id="L85" class="ln">    85</span>	(defun go--regexp-enclose-in-symbol (s)
<span id="L86" class="ln">    86</span>	  ;; XEmacs does not support \_&lt;, GNU Emacs does. In GNU Emacs we make
<span id="L87" class="ln">    87</span>	  ;; extensive use of \_&lt; to support unicode in identifiers. Until we
<span id="L88" class="ln">    88</span>	  ;; come up with a better solution for XEmacs, this solution will
<span id="L89" class="ln">    89</span>	  ;; break fontification in XEmacs for identifiers such as &#34;typeµ&#34;.
<span id="L90" class="ln">    90</span>	  ;; XEmacs will consider &#34;type&#34; a keyword, GNU Emacs won&#39;t.
<span id="L91" class="ln">    91</span>	
<span id="L92" class="ln">    92</span>	  (if (go--xemacs-p)
<span id="L93" class="ln">    93</span>	      (concat &#34;\\&lt;&#34; s &#34;\\&gt;&#34;)
<span id="L94" class="ln">    94</span>	    (concat &#34;\\_&lt;&#34; s &#34;\\_&gt;&#34;)))
<span id="L95" class="ln">    95</span>	
<span id="L96" class="ln">    96</span>	;; Move up one level of parentheses.
<span id="L97" class="ln">    97</span>	(defun go-goto-opening-parenthesis (&amp;optional legacy-unused)
<span id="L98" class="ln">    98</span>	  ;; The old implementation of go-goto-opening-parenthesis had an
<span id="L99" class="ln">    99</span>	  ;; optional argument to speed up the function. It didn&#39;t change the
<span id="L100" class="ln">   100</span>	  ;; function&#39;s outcome.
<span id="L101" class="ln">   101</span>	
<span id="L102" class="ln">   102</span>	  ;; Silently fail if there&#39;s no matching opening parenthesis.
<span id="L103" class="ln">   103</span>	  (condition-case nil
<span id="L104" class="ln">   104</span>	      (backward-up-list)
<span id="L105" class="ln">   105</span>	    (scan-error nil)))
<span id="L106" class="ln">   106</span>	
<span id="L107" class="ln">   107</span>	
<span id="L108" class="ln">   108</span>	(defconst go-dangling-operators-regexp &#34;[^-]-\\|[^+]\\+\\|[/*&amp;&gt;&lt;.=|^]&#34;)
<span id="L109" class="ln">   109</span>	(defconst go-identifier-regexp &#34;[[:word:][:multibyte:]]+&#34;)
<span id="L110" class="ln">   110</span>	(defconst go-label-regexp go-identifier-regexp)
<span id="L111" class="ln">   111</span>	(defconst go-type-regexp &#34;[[:word:][:multibyte:]*]+&#34;)
<span id="L112" class="ln">   112</span>	(defconst go-func-regexp (concat (go--regexp-enclose-in-symbol &#34;func&#34;) &#34;\\s *\\(&#34; go-identifier-regexp &#34;\\)&#34;))
<span id="L113" class="ln">   113</span>	(defconst go-func-meth-regexp (concat
<span id="L114" class="ln">   114</span>	                               (go--regexp-enclose-in-symbol &#34;func&#34;) &#34;\\s *\\(?:(\\s *&#34;
<span id="L115" class="ln">   115</span>	                               &#34;\\(&#34; go-identifier-regexp &#34;\\s +\\)?&#34; go-type-regexp
<span id="L116" class="ln">   116</span>	                               &#34;\\s *)\\s *\\)?\\(&#34;
<span id="L117" class="ln">   117</span>	                               go-identifier-regexp
<span id="L118" class="ln">   118</span>	                               &#34;\\)(&#34;))
<span id="L119" class="ln">   119</span>	(defconst go-builtins
<span id="L120" class="ln">   120</span>	  &#39;(&#34;append&#34; &#34;cap&#34;   &#34;close&#34;   &#34;complex&#34; &#34;copy&#34;
<span id="L121" class="ln">   121</span>	    &#34;delete&#34; &#34;imag&#34;  &#34;len&#34;     &#34;make&#34;    &#34;new&#34;
<span id="L122" class="ln">   122</span>	    &#34;panic&#34;  &#34;print&#34; &#34;println&#34; &#34;real&#34;    &#34;recover&#34;)
<span id="L123" class="ln">   123</span>	  &#34;All built-in functions in the Go language. Used for font locking.&#34;)
<span id="L124" class="ln">   124</span>	
<span id="L125" class="ln">   125</span>	(defconst go-mode-keywords
<span id="L126" class="ln">   126</span>	  &#39;(&#34;break&#34;    &#34;default&#34;     &#34;func&#34;   &#34;interface&#34; &#34;select&#34;
<span id="L127" class="ln">   127</span>	    &#34;case&#34;     &#34;defer&#34;       &#34;go&#34;     &#34;map&#34;       &#34;struct&#34;
<span id="L128" class="ln">   128</span>	    &#34;chan&#34;     &#34;else&#34;        &#34;goto&#34;   &#34;package&#34;   &#34;switch&#34;
<span id="L129" class="ln">   129</span>	    &#34;const&#34;    &#34;fallthrough&#34; &#34;if&#34;     &#34;range&#34;     &#34;type&#34;
<span id="L130" class="ln">   130</span>	    &#34;continue&#34; &#34;for&#34;         &#34;import&#34; &#34;return&#34;    &#34;var&#34;)
<span id="L131" class="ln">   131</span>	  &#34;All keywords in the Go language.  Used for font locking.&#34;)
<span id="L132" class="ln">   132</span>	
<span id="L133" class="ln">   133</span>	(defconst go-constants &#39;(&#34;nil&#34; &#34;true&#34; &#34;false&#34; &#34;iota&#34;))
<span id="L134" class="ln">   134</span>	(defconst go-type-name-regexp (concat &#34;\\(?:[*(]\\)*\\(?:&#34; go-identifier-regexp &#34;\\.\\)?\\(&#34; go-identifier-regexp &#34;\\)&#34;))
<span id="L135" class="ln">   135</span>	
<span id="L136" class="ln">   136</span>	(defvar go-dangling-cache)
<span id="L137" class="ln">   137</span>	(defvar go-godoc-history nil)
<span id="L138" class="ln">   138</span>	(defvar go--coverage-current-file-name)
<span id="L139" class="ln">   139</span>	
<span id="L140" class="ln">   140</span>	(defgroup go nil
<span id="L141" class="ln">   141</span>	  &#34;Major mode for editing Go code&#34;
<span id="L142" class="ln">   142</span>	  :group &#39;languages)
<span id="L143" class="ln">   143</span>	
<span id="L144" class="ln">   144</span>	(defgroup go-cover nil
<span id="L145" class="ln">   145</span>	  &#34;Options specific to `cover`&#34;
<span id="L146" class="ln">   146</span>	  :group &#39;go)
<span id="L147" class="ln">   147</span>	
<span id="L148" class="ln">   148</span>	(defcustom go-fontify-function-calls t
<span id="L149" class="ln">   149</span>	  &#34;Fontify function and method calls if this is non-nil.&#34;
<span id="L150" class="ln">   150</span>	  :type &#39;boolean
<span id="L151" class="ln">   151</span>	  :group &#39;go)
<span id="L152" class="ln">   152</span>	
<span id="L153" class="ln">   153</span>	(defcustom go-mode-hook nil
<span id="L154" class="ln">   154</span>	  &#34;Hook called by `go-mode&#39;.&#34;
<span id="L155" class="ln">   155</span>	  :type &#39;hook
<span id="L156" class="ln">   156</span>	  :group &#39;go)
<span id="L157" class="ln">   157</span>	
<span id="L158" class="ln">   158</span>	(defcustom go-command &#34;go&#34;
<span id="L159" class="ln">   159</span>	  &#34;The &#39;go&#39; command.  Some users have multiple Go development
<span id="L160" class="ln">   160</span>	trees and invoke the &#39;go&#39; tool via a wrapper that sets GOROOT and
<span id="L161" class="ln">   161</span>	GOPATH based on the current directory.  Such users should
<span id="L162" class="ln">   162</span>	customize this variable to point to the wrapper script.&#34;
<span id="L163" class="ln">   163</span>	  :type &#39;string
<span id="L164" class="ln">   164</span>	  :group &#39;go)
<span id="L165" class="ln">   165</span>	
<span id="L166" class="ln">   166</span>	(defcustom gofmt-command &#34;gofmt&#34;
<span id="L167" class="ln">   167</span>	  &#34;The &#39;gofmt&#39; command.  Some users may replace this with &#39;goimports&#39;
<span id="L168" class="ln">   168</span>	from https://github.com/bradfitz/goimports.&#34;
<span id="L169" class="ln">   169</span>	  :type &#39;string
<span id="L170" class="ln">   170</span>	  :group &#39;go)
<span id="L171" class="ln">   171</span>	
<span id="L172" class="ln">   172</span>	(defcustom go-other-file-alist
<span id="L173" class="ln">   173</span>	  &#39;((&#34;_test\\.go\\&#39;&#34; (&#34;.go&#34;))
<span id="L174" class="ln">   174</span>	    (&#34;\\.go\\&#39;&#34; (&#34;_test.go&#34;)))
<span id="L175" class="ln">   175</span>	  &#34;See the documentation of `ff-other-file-alist&#39; for details.&#34;
<span id="L176" class="ln">   176</span>	  :type &#39;(repeat (list regexp (choice (repeat string) function)))
<span id="L177" class="ln">   177</span>	  :group &#39;go)
<span id="L178" class="ln">   178</span>	
<span id="L179" class="ln">   179</span>	(defface go-coverage-untracked
<span id="L180" class="ln">   180</span>	  &#39;((t (:foreground &#34;#505050&#34;)))
<span id="L181" class="ln">   181</span>	  &#34;Coverage color of untracked code.&#34;
<span id="L182" class="ln">   182</span>	  :group &#39;go-cover)
<span id="L183" class="ln">   183</span>	
<span id="L184" class="ln">   184</span>	(defface go-coverage-0
<span id="L185" class="ln">   185</span>	  &#39;((t (:foreground &#34;#c00000&#34;)))
<span id="L186" class="ln">   186</span>	  &#34;Coverage color for uncovered code.&#34;
<span id="L187" class="ln">   187</span>	  :group &#39;go-cover)
<span id="L188" class="ln">   188</span>	(defface go-coverage-1
<span id="L189" class="ln">   189</span>	  &#39;((t (:foreground &#34;#808080&#34;)))
<span id="L190" class="ln">   190</span>	  &#34;Coverage color for covered code with weight 1.&#34;
<span id="L191" class="ln">   191</span>	  :group &#39;go-cover)
<span id="L192" class="ln">   192</span>	(defface go-coverage-2
<span id="L193" class="ln">   193</span>	  &#39;((t (:foreground &#34;#748c83&#34;)))
<span id="L194" class="ln">   194</span>	  &#34;Coverage color for covered code with weight 2.&#34;
<span id="L195" class="ln">   195</span>	  :group &#39;go-cover)
<span id="L196" class="ln">   196</span>	(defface go-coverage-3
<span id="L197" class="ln">   197</span>	  &#39;((t (:foreground &#34;#689886&#34;)))
<span id="L198" class="ln">   198</span>	  &#34;Coverage color for covered code with weight 3.&#34;
<span id="L199" class="ln">   199</span>	  :group &#39;go-cover)
<span id="L200" class="ln">   200</span>	(defface go-coverage-4
<span id="L201" class="ln">   201</span>	  &#39;((t (:foreground &#34;#5ca489&#34;)))
<span id="L202" class="ln">   202</span>	  &#34;Coverage color for covered code with weight 4.&#34;
<span id="L203" class="ln">   203</span>	  :group &#39;go-cover)
<span id="L204" class="ln">   204</span>	(defface go-coverage-5
<span id="L205" class="ln">   205</span>	  &#39;((t (:foreground &#34;#50b08c&#34;)))
<span id="L206" class="ln">   206</span>	  &#34;Coverage color for covered code with weight 5.&#34;
<span id="L207" class="ln">   207</span>	  :group &#39;go-cover)
<span id="L208" class="ln">   208</span>	(defface go-coverage-6
<span id="L209" class="ln">   209</span>	  &#39;((t (:foreground &#34;#44bc8f&#34;)))
<span id="L210" class="ln">   210</span>	  &#34;Coverage color for covered code with weight 6.&#34;
<span id="L211" class="ln">   211</span>	  :group &#39;go-cover)
<span id="L212" class="ln">   212</span>	(defface go-coverage-7
<span id="L213" class="ln">   213</span>	  &#39;((t (:foreground &#34;#38c892&#34;)))
<span id="L214" class="ln">   214</span>	  &#34;Coverage color for covered code with weight 7.&#34;
<span id="L215" class="ln">   215</span>	  :group &#39;go-cover)
<span id="L216" class="ln">   216</span>	(defface go-coverage-8
<span id="L217" class="ln">   217</span>	  &#39;((t (:foreground &#34;#2cd495&#34;)))
<span id="L218" class="ln">   218</span>	  &#34;Coverage color for covered code with weight 8.
<span id="L219" class="ln">   219</span>	For mode=set, all covered lines will have this weight.&#34;
<span id="L220" class="ln">   220</span>	  :group &#39;go-cover)
<span id="L221" class="ln">   221</span>	(defface go-coverage-9
<span id="L222" class="ln">   222</span>	  &#39;((t (:foreground &#34;#20e098&#34;)))
<span id="L223" class="ln">   223</span>	  &#34;Coverage color for covered code with weight 9.&#34;
<span id="L224" class="ln">   224</span>	  :group &#39;go-cover)
<span id="L225" class="ln">   225</span>	(defface go-coverage-10
<span id="L226" class="ln">   226</span>	  &#39;((t (:foreground &#34;#14ec9b&#34;)))
<span id="L227" class="ln">   227</span>	  &#34;Coverage color for covered code with weight 10.&#34;
<span id="L228" class="ln">   228</span>	  :group &#39;go-cover)
<span id="L229" class="ln">   229</span>	(defface go-coverage-covered
<span id="L230" class="ln">   230</span>	  &#39;((t (:foreground &#34;#2cd495&#34;)))
<span id="L231" class="ln">   231</span>	  &#34;Coverage color of covered code.&#34;
<span id="L232" class="ln">   232</span>	  :group &#39;go-cover)
<span id="L233" class="ln">   233</span>	
<span id="L234" class="ln">   234</span>	(defvar go-mode-syntax-table
<span id="L235" class="ln">   235</span>	  (let ((st (make-syntax-table)))
<span id="L236" class="ln">   236</span>	    (modify-syntax-entry ?+  &#34;.&#34; st)
<span id="L237" class="ln">   237</span>	    (modify-syntax-entry ?-  &#34;.&#34; st)
<span id="L238" class="ln">   238</span>	    (modify-syntax-entry ?%  &#34;.&#34; st)
<span id="L239" class="ln">   239</span>	    (modify-syntax-entry ?&amp;  &#34;.&#34; st)
<span id="L240" class="ln">   240</span>	    (modify-syntax-entry ?|  &#34;.&#34; st)
<span id="L241" class="ln">   241</span>	    (modify-syntax-entry ?^  &#34;.&#34; st)
<span id="L242" class="ln">   242</span>	    (modify-syntax-entry ?!  &#34;.&#34; st)
<span id="L243" class="ln">   243</span>	    (modify-syntax-entry ?=  &#34;.&#34; st)
<span id="L244" class="ln">   244</span>	    (modify-syntax-entry ?&lt;  &#34;.&#34; st)
<span id="L245" class="ln">   245</span>	    (modify-syntax-entry ?&gt;  &#34;.&#34; st)
<span id="L246" class="ln">   246</span>	    (modify-syntax-entry ?/ (if (go--xemacs-p) &#34;. 1456&#34; &#34;. 124b&#34;) st)
<span id="L247" class="ln">   247</span>	    (modify-syntax-entry ?*  &#34;. 23&#34; st)
<span id="L248" class="ln">   248</span>	    (modify-syntax-entry ?\n &#34;&gt; b&#34; st)
<span id="L249" class="ln">   249</span>	    (modify-syntax-entry ?\&#34; &#34;\&#34;&#34; st)
<span id="L250" class="ln">   250</span>	    (modify-syntax-entry ?\&#39; &#34;\&#34;&#34; st)
<span id="L251" class="ln">   251</span>	    (modify-syntax-entry ?`  &#34;\&#34;&#34; st)
<span id="L252" class="ln">   252</span>	    (modify-syntax-entry ?\\ &#34;\\&#34; st)
<span id="L253" class="ln">   253</span>	    ;; It would be nicer to have _ as a symbol constituent, but that
<span id="L254" class="ln">   254</span>	    ;; would trip up XEmacs, which does not support the \_&lt; anchor
<span id="L255" class="ln">   255</span>	    (modify-syntax-entry ?_  &#34;w&#34; st)
<span id="L256" class="ln">   256</span>	
<span id="L257" class="ln">   257</span>	    st)
<span id="L258" class="ln">   258</span>	  &#34;Syntax table for Go mode.&#34;)
<span id="L259" class="ln">   259</span>	
<span id="L260" class="ln">   260</span>	(defun go--build-font-lock-keywords ()
<span id="L261" class="ln">   261</span>	  ;; we cannot use &#39;symbols in regexp-opt because GNU Emacs &lt;24
<span id="L262" class="ln">   262</span>	  ;; doesn&#39;t understand that
<span id="L263" class="ln">   263</span>	  (append
<span id="L264" class="ln">   264</span>	   `((,(go--regexp-enclose-in-symbol (regexp-opt go-mode-keywords t)) . font-lock-keyword-face)
<span id="L265" class="ln">   265</span>	     (,(concat &#34;\\(&#34; (go--regexp-enclose-in-symbol (regexp-opt go-builtins t)) &#34;\\)[[:space:]]*(&#34;) 1 font-lock-builtin-face)
<span id="L266" class="ln">   266</span>	     (,(go--regexp-enclose-in-symbol (regexp-opt go-constants t)) . font-lock-constant-face)
<span id="L267" class="ln">   267</span>	     (,go-func-regexp 1 font-lock-function-name-face)) ;; function (not method) name
<span id="L268" class="ln">   268</span>	
<span id="L269" class="ln">   269</span>	   (if go-fontify-function-calls
<span id="L270" class="ln">   270</span>	       `((,(concat &#34;\\(&#34; go-identifier-regexp &#34;\\)[[:space:]]*(&#34;) 1 font-lock-function-name-face) ;; function call/method name
<span id="L271" class="ln">   271</span>	         (,(concat &#34;[^[:word:][:multibyte:]](\\(&#34; go-identifier-regexp &#34;\\))[[:space:]]*(&#34;) 1 font-lock-function-name-face)) ;; bracketed function call
<span id="L272" class="ln">   272</span>	     `((,go-func-meth-regexp 2 font-lock-function-name-face))) ;; method name
<span id="L273" class="ln">   273</span>	
<span id="L274" class="ln">   274</span>	   `(
<span id="L275" class="ln">   275</span>	     (&#34;\\(`[^`]*`\\)&#34; 1 font-lock-multiline) ;; raw string literal, needed for font-lock-syntactic-keywords
<span id="L276" class="ln">   276</span>	     (,(concat (go--regexp-enclose-in-symbol &#34;type&#34;) &#34;[[:space:]]+\\([^[:space:]]+\\)&#34;) 1 font-lock-type-face) ;; types
<span id="L277" class="ln">   277</span>	     (,(concat (go--regexp-enclose-in-symbol &#34;type&#34;) &#34;[[:space:]]+&#34; go-identifier-regexp &#34;[[:space:]]*&#34; go-type-name-regexp) 1 font-lock-type-face) ;; types
<span id="L278" class="ln">   278</span>	     (,(concat &#34;[^[:word:][:multibyte:]]\\[\\([[:digit:]]+\\|\\.\\.\\.\\)?\\]&#34; go-type-name-regexp) 2 font-lock-type-face) ;; Arrays/slices
<span id="L279" class="ln">   279</span>	     (,(concat &#34;\\(&#34; go-identifier-regexp &#34;\\)&#34; &#34;{&#34;) 1 font-lock-type-face)
<span id="L280" class="ln">   280</span>	     (,(concat (go--regexp-enclose-in-symbol &#34;map&#34;) &#34;\\[[^]]+\\]&#34; go-type-name-regexp) 1 font-lock-type-face) ;; map value type
<span id="L281" class="ln">   281</span>	     (,(concat (go--regexp-enclose-in-symbol &#34;map&#34;) &#34;\\[&#34; go-type-name-regexp) 1 font-lock-type-face) ;; map key type
<span id="L282" class="ln">   282</span>	     (,(concat (go--regexp-enclose-in-symbol &#34;chan&#34;) &#34;[[:space:]]*\\(?:&lt;-\\)?&#34; go-type-name-regexp) 1 font-lock-type-face) ;; channel type
<span id="L283" class="ln">   283</span>	     (,(concat (go--regexp-enclose-in-symbol &#34;\\(?:new\\|make\\)&#34;) &#34;\\(?:[[:space:]]\\|)\\)*(&#34; go-type-name-regexp) 1 font-lock-type-face) ;; new/make type
<span id="L284" class="ln">   284</span>	     ;; TODO do we actually need this one or isn&#39;t it just a function call?
<span id="L285" class="ln">   285</span>	     (,(concat &#34;\\.\\s *(&#34; go-type-name-regexp) 1 font-lock-type-face) ;; Type conversion
<span id="L286" class="ln">   286</span>	     (,(concat (go--regexp-enclose-in-symbol &#34;func&#34;) &#34;[[:space:]]+(&#34; go-identifier-regexp &#34;[[:space:]]+&#34; go-type-name-regexp &#34;)&#34;) 1 font-lock-type-face) ;; Method receiver
<span id="L287" class="ln">   287</span>	     (,(concat (go--regexp-enclose-in-symbol &#34;func&#34;) &#34;[[:space:]]+(&#34; go-type-name-regexp &#34;)&#34;) 1 font-lock-type-face) ;; Method receiver without variable name
<span id="L288" class="ln">   288</span>	     ;; Like the original go-mode this also marks compound literal
<span id="L289" class="ln">   289</span>	     ;; fields. There, it was marked as to fix, but I grew quite
<span id="L290" class="ln">   290</span>	     ;; accustomed to it, so it&#39;ll stay for now.
<span id="L291" class="ln">   291</span>	     (,(concat &#34;^[[:space:]]*\\(&#34; go-label-regexp &#34;\\)[[:space:]]*:\\(\\S.\\|$\\)&#34;) 1 font-lock-constant-face) ;; Labels and compound literal fields
<span id="L292" class="ln">   292</span>	     (,(concat (go--regexp-enclose-in-symbol &#34;\\(goto\\|break\\|continue\\)&#34;) &#34;[[:space:]]*\\(&#34; go-label-regexp &#34;\\)&#34;) 2 font-lock-constant-face)))) ;; labels in goto/break/continue
<span id="L293" class="ln">   293</span>	
<span id="L294" class="ln">   294</span>	(defconst go--font-lock-syntactic-keywords
<span id="L295" class="ln">   295</span>	  ;; Override syntax property of raw string literal contents, so that
<span id="L296" class="ln">   296</span>	  ;; backslashes have no special meaning in ``. Used in Emacs 23 or older.
<span id="L297" class="ln">   297</span>	  &#39;((go--match-raw-string-literal
<span id="L298" class="ln">   298</span>	     (1 (7 . ?`))
<span id="L299" class="ln">   299</span>	     (2 (15 . nil))  ;; 15 = &#34;generic string&#34;
<span id="L300" class="ln">   300</span>	     (3 (7 . ?`)))))
<span id="L301" class="ln">   301</span>	
<span id="L302" class="ln">   302</span>	(defvar go-mode-map
<span id="L303" class="ln">   303</span>	  (let ((m (make-sparse-keymap)))
<span id="L304" class="ln">   304</span>	    (define-key m &#34;}&#34; #&#39;go-mode-insert-and-indent)
<span id="L305" class="ln">   305</span>	    (define-key m &#34;)&#34; #&#39;go-mode-insert-and-indent)
<span id="L306" class="ln">   306</span>	    (define-key m &#34;,&#34; #&#39;go-mode-insert-and-indent)
<span id="L307" class="ln">   307</span>	    (define-key m &#34;:&#34; #&#39;go-mode-insert-and-indent)
<span id="L308" class="ln">   308</span>	    (define-key m &#34;=&#34; #&#39;go-mode-insert-and-indent)
<span id="L309" class="ln">   309</span>	    (define-key m (kbd &#34;C-c C-a&#34;) #&#39;go-import-add)
<span id="L310" class="ln">   310</span>	    (define-key m (kbd &#34;C-c C-j&#34;) #&#39;godef-jump)
<span id="L311" class="ln">   311</span>	    (define-key m (kbd &#34;C-x 4 C-c C-j&#34;) #&#39;godef-jump-other-window)
<span id="L312" class="ln">   312</span>	    (define-key m (kbd &#34;C-c C-d&#34;) #&#39;godef-describe)
<span id="L313" class="ln">   313</span>	    m)
<span id="L314" class="ln">   314</span>	  &#34;Keymap used by Go mode to implement electric keys.&#34;)
<span id="L315" class="ln">   315</span>	
<span id="L316" class="ln">   316</span>	(defun go-mode-insert-and-indent (key)
<span id="L317" class="ln">   317</span>	  &#34;Invoke the global binding of KEY, then reindent the line.&#34;
<span id="L318" class="ln">   318</span>	
<span id="L319" class="ln">   319</span>	  (interactive (list (this-command-keys)))
<span id="L320" class="ln">   320</span>	  (call-interactively (lookup-key (current-global-map) key))
<span id="L321" class="ln">   321</span>	  (indent-according-to-mode))
<span id="L322" class="ln">   322</span>	
<span id="L323" class="ln">   323</span>	(defmacro go-paren-level ()
<span id="L324" class="ln">   324</span>	  `(car (syntax-ppss)))
<span id="L325" class="ln">   325</span>	
<span id="L326" class="ln">   326</span>	(defmacro go-in-string-or-comment-p ()
<span id="L327" class="ln">   327</span>	  `(nth 8 (syntax-ppss)))
<span id="L328" class="ln">   328</span>	
<span id="L329" class="ln">   329</span>	(defmacro go-in-string-p ()
<span id="L330" class="ln">   330</span>	  `(nth 3 (syntax-ppss)))
<span id="L331" class="ln">   331</span>	
<span id="L332" class="ln">   332</span>	(defmacro go-in-comment-p ()
<span id="L333" class="ln">   333</span>	  `(nth 4 (syntax-ppss)))
<span id="L334" class="ln">   334</span>	
<span id="L335" class="ln">   335</span>	(defmacro go-goto-beginning-of-string-or-comment ()
<span id="L336" class="ln">   336</span>	  `(goto-char (nth 8 (syntax-ppss))))
<span id="L337" class="ln">   337</span>	
<span id="L338" class="ln">   338</span>	(defun go--backward-irrelevant (&amp;optional stop-at-string)
<span id="L339" class="ln">   339</span>	  &#34;Skips backwards over any characters that are irrelevant for
<span id="L340" class="ln">   340</span>	indentation and related tasks.
<span id="L341" class="ln">   341</span>	
<span id="L342" class="ln">   342</span>	It skips over whitespace, comments, cases and labels and, if
<span id="L343" class="ln">   343</span>	STOP-AT-STRING is not true, over strings.&#34;
<span id="L344" class="ln">   344</span>	
<span id="L345" class="ln">   345</span>	  (let (pos (start-pos (point)))
<span id="L346" class="ln">   346</span>	    (skip-chars-backward &#34;\n\s\t&#34;)
<span id="L347" class="ln">   347</span>	    (if (and (save-excursion (beginning-of-line) (go-in-string-p)) (looking-back &#34;`&#34;) (not stop-at-string))
<span id="L348" class="ln">   348</span>	        (backward-char))
<span id="L349" class="ln">   349</span>	    (if (and (go-in-string-p) (not stop-at-string))
<span id="L350" class="ln">   350</span>	        (go-goto-beginning-of-string-or-comment))
<span id="L351" class="ln">   351</span>	    (if (looking-back &#34;\\*/&#34;)
<span id="L352" class="ln">   352</span>	        (backward-char))
<span id="L353" class="ln">   353</span>	    (if (go-in-comment-p)
<span id="L354" class="ln">   354</span>	        (go-goto-beginning-of-string-or-comment))
<span id="L355" class="ln">   355</span>	    (setq pos (point))
<span id="L356" class="ln">   356</span>	    (beginning-of-line)
<span id="L357" class="ln">   357</span>	    (if (or (looking-at (concat &#34;^&#34; go-label-regexp &#34;:&#34;)) (looking-at &#34;^[[:space:]]*\\(case .+\\|default\\):&#34;))
<span id="L358" class="ln">   358</span>	        (end-of-line 0)
<span id="L359" class="ln">   359</span>	      (goto-char pos))
<span id="L360" class="ln">   360</span>	    (if (/= start-pos (point))
<span id="L361" class="ln">   361</span>	        (go--backward-irrelevant stop-at-string))
<span id="L362" class="ln">   362</span>	    (/= start-pos (point))))
<span id="L363" class="ln">   363</span>	
<span id="L364" class="ln">   364</span>	(defun go--buffer-narrowed-p ()
<span id="L365" class="ln">   365</span>	  &#34;Return non-nil if the current buffer is narrowed.&#34;
<span id="L366" class="ln">   366</span>	  (/= (buffer-size)
<span id="L367" class="ln">   367</span>	      (- (point-max)
<span id="L368" class="ln">   368</span>	         (point-min))))
<span id="L369" class="ln">   369</span>	
<span id="L370" class="ln">   370</span>	(defun go--match-raw-string-literal (end)
<span id="L371" class="ln">   371</span>	  &#34;Search for a raw string literal. Set point to the end of the
<span id="L372" class="ln">   372</span>	occurence found on success. Returns nil on failure.&#34;
<span id="L373" class="ln">   373</span>	  (when (search-forward &#34;`&#34; end t)
<span id="L374" class="ln">   374</span>	    (goto-char (match-beginning 0))
<span id="L375" class="ln">   375</span>	    (if (go-in-string-or-comment-p)
<span id="L376" class="ln">   376</span>	        (progn (goto-char (match-end 0))
<span id="L377" class="ln">   377</span>	               (go--match-raw-string-literal end))
<span id="L378" class="ln">   378</span>	      (when (looking-at &#34;\\(`\\)\\([^`]*\\)\\(`\\)&#34;)
<span id="L379" class="ln">   379</span>	        (goto-char (match-end 0))
<span id="L380" class="ln">   380</span>	        t))))
<span id="L381" class="ln">   381</span>	
<span id="L382" class="ln">   382</span>	(defun go-previous-line-has-dangling-op-p ()
<span id="L383" class="ln">   383</span>	  &#34;Returns non-nil if the current line is a continuation line.&#34;
<span id="L384" class="ln">   384</span>	  (let* ((cur-line (line-number-at-pos))
<span id="L385" class="ln">   385</span>	         (val (gethash cur-line go-dangling-cache &#39;nope)))
<span id="L386" class="ln">   386</span>	    (if (or (go--buffer-narrowed-p) (equal val &#39;nope))
<span id="L387" class="ln">   387</span>	        (save-excursion
<span id="L388" class="ln">   388</span>	          (beginning-of-line)
<span id="L389" class="ln">   389</span>	          (go--backward-irrelevant t)
<span id="L390" class="ln">   390</span>	          (setq val (looking-back go-dangling-operators-regexp))
<span id="L391" class="ln">   391</span>	          (if (not (go--buffer-narrowed-p))
<span id="L392" class="ln">   392</span>	              (puthash cur-line val go-dangling-cache))))
<span id="L393" class="ln">   393</span>	    val))
<span id="L394" class="ln">   394</span>	
<span id="L395" class="ln">   395</span>	(defun go--at-function-definition ()
<span id="L396" class="ln">   396</span>	  &#34;Return non-nil if point is on the opening curly brace of a
<span id="L397" class="ln">   397</span>	function definition.
<span id="L398" class="ln">   398</span>	
<span id="L399" class="ln">   399</span>	We do this by first calling (beginning-of-defun), which will take
<span id="L400" class="ln">   400</span>	us to the start of *some* function. We then look for the opening
<span id="L401" class="ln">   401</span>	curly brace of that function and compare its position against the
<span id="L402" class="ln">   402</span>	curly brace we are checking. If they match, we return non-nil.&#34;
<span id="L403" class="ln">   403</span>	  (if (= (char-after) ?\{)
<span id="L404" class="ln">   404</span>	      (save-excursion
<span id="L405" class="ln">   405</span>	        (let ((old-point (point))
<span id="L406" class="ln">   406</span>	              start-nesting)
<span id="L407" class="ln">   407</span>	          (beginning-of-defun)
<span id="L408" class="ln">   408</span>	          (when (looking-at &#34;func &#34;)
<span id="L409" class="ln">   409</span>	            (setq start-nesting (go-paren-level))
<span id="L410" class="ln">   410</span>	            (skip-chars-forward &#34;^{&#34;)
<span id="L411" class="ln">   411</span>	            (while (&gt; (go-paren-level) start-nesting)
<span id="L412" class="ln">   412</span>	              (forward-char)
<span id="L413" class="ln">   413</span>	              (skip-chars-forward &#34;^{&#34;) 0)
<span id="L414" class="ln">   414</span>	            (if (and (= (go-paren-level) start-nesting) (= old-point (point)))
<span id="L415" class="ln">   415</span>	                t))))))
<span id="L416" class="ln">   416</span>	
<span id="L417" class="ln">   417</span>	(defun go--indentation-for-opening-parenthesis ()
<span id="L418" class="ln">   418</span>	  &#34;Return the semantic indentation for the current opening parenthesis.
<span id="L419" class="ln">   419</span>	
<span id="L420" class="ln">   420</span>	If point is on an opening curly brace and said curly brace
<span id="L421" class="ln">   421</span>	belongs to a function declaration, the indentation of the func
<span id="L422" class="ln">   422</span>	keyword will be returned. Otherwise the indentation of the
<span id="L423" class="ln">   423</span>	current line will be returned.&#34;
<span id="L424" class="ln">   424</span>	  (save-excursion
<span id="L425" class="ln">   425</span>	    (if (go--at-function-definition)
<span id="L426" class="ln">   426</span>	        (progn
<span id="L427" class="ln">   427</span>	          (beginning-of-defun)
<span id="L428" class="ln">   428</span>	          (current-indentation))
<span id="L429" class="ln">   429</span>	      (current-indentation))))
<span id="L430" class="ln">   430</span>	
<span id="L431" class="ln">   431</span>	(defun go-indentation-at-point ()
<span id="L432" class="ln">   432</span>	  (save-excursion
<span id="L433" class="ln">   433</span>	    (let (start-nesting)
<span id="L434" class="ln">   434</span>	      (back-to-indentation)
<span id="L435" class="ln">   435</span>	      (setq start-nesting (go-paren-level))
<span id="L436" class="ln">   436</span>	
<span id="L437" class="ln">   437</span>	      (cond
<span id="L438" class="ln">   438</span>	       ((go-in-string-p)
<span id="L439" class="ln">   439</span>	        (current-indentation))
<span id="L440" class="ln">   440</span>	       ((looking-at &#34;[])}]&#34;)
<span id="L441" class="ln">   441</span>	        (go-goto-opening-parenthesis)
<span id="L442" class="ln">   442</span>	        (if (go-previous-line-has-dangling-op-p)
<span id="L443" class="ln">   443</span>	            (- (current-indentation) tab-width)
<span id="L444" class="ln">   444</span>	          (go--indentation-for-opening-parenthesis)))
<span id="L445" class="ln">   445</span>	       ((progn (go--backward-irrelevant t) (looking-back go-dangling-operators-regexp))
<span id="L446" class="ln">   446</span>	        ;; only one nesting for all dangling operators in one operation
<span id="L447" class="ln">   447</span>	        (if (go-previous-line-has-dangling-op-p)
<span id="L448" class="ln">   448</span>	            (current-indentation)
<span id="L449" class="ln">   449</span>	          (+ (current-indentation) tab-width)))
<span id="L450" class="ln">   450</span>	       ((zerop (go-paren-level))
<span id="L451" class="ln">   451</span>	        0)
<span id="L452" class="ln">   452</span>	       ((progn (go-goto-opening-parenthesis) (&lt; (go-paren-level) start-nesting))
<span id="L453" class="ln">   453</span>	        (if (go-previous-line-has-dangling-op-p)
<span id="L454" class="ln">   454</span>	            (current-indentation)
<span id="L455" class="ln">   455</span>	          (+ (go--indentation-for-opening-parenthesis) tab-width)))
<span id="L456" class="ln">   456</span>	       (t
<span id="L457" class="ln">   457</span>	        (current-indentation))))))
<span id="L458" class="ln">   458</span>	
<span id="L459" class="ln">   459</span>	(defun go-mode-indent-line ()
<span id="L460" class="ln">   460</span>	  (interactive)
<span id="L461" class="ln">   461</span>	  (let (indent
<span id="L462" class="ln">   462</span>	        shift-amt
<span id="L463" class="ln">   463</span>	        (pos (- (point-max) (point)))
<span id="L464" class="ln">   464</span>	        (point (point))
<span id="L465" class="ln">   465</span>	        (beg (line-beginning-position)))
<span id="L466" class="ln">   466</span>	    (back-to-indentation)
<span id="L467" class="ln">   467</span>	    (if (go-in-string-or-comment-p)
<span id="L468" class="ln">   468</span>	        (goto-char point)
<span id="L469" class="ln">   469</span>	      (setq indent (go-indentation-at-point))
<span id="L470" class="ln">   470</span>	      (if (looking-at (concat go-label-regexp &#34;:\\([[:space:]]*/.+\\)?$\\|case .+:\\|default:&#34;))
<span id="L471" class="ln">   471</span>	          (decf indent tab-width))
<span id="L472" class="ln">   472</span>	      (setq shift-amt (- indent (current-column)))
<span id="L473" class="ln">   473</span>	      (if (zerop shift-amt)
<span id="L474" class="ln">   474</span>	          nil
<span id="L475" class="ln">   475</span>	        (delete-region beg (point))
<span id="L476" class="ln">   476</span>	        (indent-to indent))
<span id="L477" class="ln">   477</span>	      ;; If initial point was within line&#39;s indentation,
<span id="L478" class="ln">   478</span>	      ;; position after the indentation.  Else stay at same point in text.
<span id="L479" class="ln">   479</span>	      (if (&gt; (- (point-max) pos) (point))
<span id="L480" class="ln">   480</span>	          (goto-char (- (point-max) pos))))))
<span id="L481" class="ln">   481</span>	
<span id="L482" class="ln">   482</span>	(defun go-beginning-of-defun (&amp;optional count)
<span id="L483" class="ln">   483</span>	  (setq count (or count 1))
<span id="L484" class="ln">   484</span>	  (let ((first t)
<span id="L485" class="ln">   485</span>	        failure)
<span id="L486" class="ln">   486</span>	    (dotimes (i (abs count))
<span id="L487" class="ln">   487</span>	      (while (and (not failure)
<span id="L488" class="ln">   488</span>	                  (or first (go-in-string-or-comment-p)))
<span id="L489" class="ln">   489</span>	        (if (&gt;= count 0)
<span id="L490" class="ln">   490</span>	            (progn
<span id="L491" class="ln">   491</span>	              (go--backward-irrelevant)
<span id="L492" class="ln">   492</span>	              (if (not (re-search-backward go-func-meth-regexp nil t))
<span id="L493" class="ln">   493</span>	                  (setq failure t)))
<span id="L494" class="ln">   494</span>	          (if (looking-at go-func-meth-regexp)
<span id="L495" class="ln">   495</span>	              (forward-char))
<span id="L496" class="ln">   496</span>	          (if (not (re-search-forward go-func-meth-regexp nil t))
<span id="L497" class="ln">   497</span>	              (setq failure t)))
<span id="L498" class="ln">   498</span>	        (setq first nil)))
<span id="L499" class="ln">   499</span>	    (if (&lt; count 0)
<span id="L500" class="ln">   500</span>	        (beginning-of-line))
<span id="L501" class="ln">   501</span>	    (not failure)))
<span id="L502" class="ln">   502</span>	
<span id="L503" class="ln">   503</span>	(defun go-end-of-defun ()
<span id="L504" class="ln">   504</span>	  (let (orig-level)
<span id="L505" class="ln">   505</span>	    ;; It can happen that we&#39;re not placed before a function by emacs
<span id="L506" class="ln">   506</span>	    (if (not (looking-at &#34;func&#34;))
<span id="L507" class="ln">   507</span>	        (go-beginning-of-defun -1))
<span id="L508" class="ln">   508</span>	    (skip-chars-forward &#34;^{&#34;)
<span id="L509" class="ln">   509</span>	    (forward-char)
<span id="L510" class="ln">   510</span>	    (setq orig-level (go-paren-level))
<span id="L511" class="ln">   511</span>	    (while (&gt;= (go-paren-level) orig-level)
<span id="L512" class="ln">   512</span>	      (skip-chars-forward &#34;^}&#34;)
<span id="L513" class="ln">   513</span>	      (forward-char))))
<span id="L514" class="ln">   514</span>	
<span id="L515" class="ln">   515</span>	;;;###autoload
<span id="L516" class="ln">   516</span>	(define-derived-mode go-mode prog-mode &#34;Go&#34;
<span id="L517" class="ln">   517</span>	  &#34;Major mode for editing Go source text.
<span id="L518" class="ln">   518</span>	
<span id="L519" class="ln">   519</span>	This mode provides (not just) basic editing capabilities for
<span id="L520" class="ln">   520</span>	working with Go code. It offers almost complete syntax
<span id="L521" class="ln">   521</span>	highlighting, indentation that is almost identical to gofmt and
<span id="L522" class="ln">   522</span>	proper parsing of the buffer content to allow features such as
<span id="L523" class="ln">   523</span>	navigation by function, manipulation of comments or detection of
<span id="L524" class="ln">   524</span>	strings.
<span id="L525" class="ln">   525</span>	
<span id="L526" class="ln">   526</span>	In addition to these core features, it offers various features to
<span id="L527" class="ln">   527</span>	help with writing Go code. You can directly run buffer content
<span id="L528" class="ln">   528</span>	through gofmt, read godoc documentation from within Emacs, modify
<span id="L529" class="ln">   529</span>	and clean up the list of package imports or interact with the
<span id="L530" class="ln">   530</span>	Playground (uploading and downloading pastes).
<span id="L531" class="ln">   531</span>	
<span id="L532" class="ln">   532</span>	The following extra functions are defined:
<span id="L533" class="ln">   533</span>	
<span id="L534" class="ln">   534</span>	- `gofmt&#39;
<span id="L535" class="ln">   535</span>	- `godoc&#39;
<span id="L536" class="ln">   536</span>	- `go-import-add&#39;
<span id="L537" class="ln">   537</span>	- `go-remove-unused-imports&#39;
<span id="L538" class="ln">   538</span>	- `go-goto-imports&#39;
<span id="L539" class="ln">   539</span>	- `go-play-buffer&#39; and `go-play-region&#39;
<span id="L540" class="ln">   540</span>	- `go-download-play&#39;
<span id="L541" class="ln">   541</span>	- `godef-describe&#39; and `godef-jump&#39;
<span id="L542" class="ln">   542</span>	- `go-coverage&#39;
<span id="L543" class="ln">   543</span>	
<span id="L544" class="ln">   544</span>	If you want to automatically run `gofmt&#39; before saving a file,
<span id="L545" class="ln">   545</span>	add the following hook to your emacs configuration:
<span id="L546" class="ln">   546</span>	
<span id="L547" class="ln">   547</span>	\(add-hook &#39;before-save-hook #&#39;gofmt-before-save)
<span id="L548" class="ln">   548</span>	
<span id="L549" class="ln">   549</span>	If you want to use `godef-jump&#39; instead of etags (or similar),
<span id="L550" class="ln">   550</span>	consider binding godef-jump to `M-.&#39;, which is the default key
<span id="L551" class="ln">   551</span>	for `find-tag&#39;:
<span id="L552" class="ln">   552</span>	
<span id="L553" class="ln">   553</span>	\(add-hook &#39;go-mode-hook (lambda ()
<span id="L554" class="ln">   554</span>	                          (local-set-key (kbd \&#34;M-.\&#34;) #&#39;godef-jump)))
<span id="L555" class="ln">   555</span>	
<span id="L556" class="ln">   556</span>	Please note that godef is an external dependency. You can install
<span id="L557" class="ln">   557</span>	it with
<span id="L558" class="ln">   558</span>	
<span id="L559" class="ln">   559</span>	go get code.google.com/p/rog-go/exp/cmd/godef
<span id="L560" class="ln">   560</span>	
<span id="L561" class="ln">   561</span>	
<span id="L562" class="ln">   562</span>	If you&#39;re looking for even more integration with Go, namely
<span id="L563" class="ln">   563</span>	on-the-fly syntax checking, auto-completion and snippets, it is
<span id="L564" class="ln">   564</span>	recommended that you look at goflymake
<span id="L565" class="ln">   565</span>	\(https://github.com/dougm/goflymake), gocode
<span id="L566" class="ln">   566</span>	\(https://github.com/nsf/gocode), go-eldoc
<span id="L567" class="ln">   567</span>	\(github.com/syohex/emacs-go-eldoc) and yasnippet-go
<span id="L568" class="ln">   568</span>	\(https://github.com/dominikh/yasnippet-go)&#34;
<span id="L569" class="ln">   569</span>	
<span id="L570" class="ln">   570</span>	  ;; Font lock
<span id="L571" class="ln">   571</span>	  (set (make-local-variable &#39;font-lock-defaults)
<span id="L572" class="ln">   572</span>	       &#39;(go--build-font-lock-keywords))
<span id="L573" class="ln">   573</span>	
<span id="L574" class="ln">   574</span>	  ;; Indentation
<span id="L575" class="ln">   575</span>	  (set (make-local-variable &#39;indent-line-function) #&#39;go-mode-indent-line)
<span id="L576" class="ln">   576</span>	
<span id="L577" class="ln">   577</span>	  ;; Comments
<span id="L578" class="ln">   578</span>	  (set (make-local-variable &#39;comment-start) &#34;// &#34;)
<span id="L579" class="ln">   579</span>	  (set (make-local-variable &#39;comment-end)   &#34;&#34;)
<span id="L580" class="ln">   580</span>	  (set (make-local-variable &#39;comment-use-syntax) t)
<span id="L581" class="ln">   581</span>	  (set (make-local-variable &#39;comment-start-skip) &#34;\\(//+\\|/\\*+\\)\\s *&#34;)
<span id="L582" class="ln">   582</span>	
<span id="L583" class="ln">   583</span>	  (set (make-local-variable &#39;beginning-of-defun-function) #&#39;go-beginning-of-defun)
<span id="L584" class="ln">   584</span>	  (set (make-local-variable &#39;end-of-defun-function) #&#39;go-end-of-defun)
<span id="L585" class="ln">   585</span>	
<span id="L586" class="ln">   586</span>	  (set (make-local-variable &#39;parse-sexp-lookup-properties) t)
<span id="L587" class="ln">   587</span>	  (if (boundp &#39;syntax-propertize-function)
<span id="L588" class="ln">   588</span>	      (set (make-local-variable &#39;syntax-propertize-function) #&#39;go-propertize-syntax)
<span id="L589" class="ln">   589</span>	    (set (make-local-variable &#39;font-lock-syntactic-keywords)
<span id="L590" class="ln">   590</span>	         go--font-lock-syntactic-keywords)
<span id="L591" class="ln">   591</span>	    (set (make-local-variable &#39;font-lock-multiline) t))
<span id="L592" class="ln">   592</span>	
<span id="L593" class="ln">   593</span>	  (set (make-local-variable &#39;go-dangling-cache) (make-hash-table :test &#39;eql))
<span id="L594" class="ln">   594</span>	  (add-hook &#39;before-change-functions (lambda (x y) (setq go-dangling-cache (make-hash-table :test &#39;eql))) t t)
<span id="L595" class="ln">   595</span>	
<span id="L596" class="ln">   596</span>	  ;; ff-find-other-file
<span id="L597" class="ln">   597</span>	  (setq ff-other-file-alist &#39;go-other-file-alist)
<span id="L598" class="ln">   598</span>	
<span id="L599" class="ln">   599</span>	  (setq imenu-generic-expression
<span id="L600" class="ln">   600</span>	        &#39;((&#34;type&#34; &#34;^type *\\([^ \t\n\r\f]*\\)&#34; 1)
<span id="L601" class="ln">   601</span>	          (&#34;func&#34; &#34;^func *\\(.*\\) {&#34; 1)))
<span id="L602" class="ln">   602</span>	  (imenu-add-to-menubar &#34;Index&#34;)
<span id="L603" class="ln">   603</span>	
<span id="L604" class="ln">   604</span>	  ;; Go style
<span id="L605" class="ln">   605</span>	  (setq indent-tabs-mode t)
<span id="L606" class="ln">   606</span>	
<span id="L607" class="ln">   607</span>	  ;; Handle unit test failure output in compilation-mode
<span id="L608" class="ln">   608</span>	  ;;
<span id="L609" class="ln">   609</span>	  ;; Note the final t argument to add-to-list for append, ie put these at the
<span id="L610" class="ln">   610</span>	  ;; *ends* of compilation-error-regexp-alist[-alist]. We want go-test to be
<span id="L611" class="ln">   611</span>	  ;; handled first, otherwise other elements will match that don&#39;t work, and
<span id="L612" class="ln">   612</span>	  ;; those alists are traversed in *reverse* order:
<span id="L613" class="ln">   613</span>	  ;; http://lists.gnu.org/archive/html/bug-gnu-emacs/2001-12/msg00674.html
<span id="L614" class="ln">   614</span>	  (when (and (boundp &#39;compilation-error-regexp-alist)
<span id="L615" class="ln">   615</span>	             (boundp &#39;compilation-error-regexp-alist-alist))
<span id="L616" class="ln">   616</span>	    (add-to-list &#39;compilation-error-regexp-alist &#39;go-test t)
<span id="L617" class="ln">   617</span>	    (add-to-list &#39;compilation-error-regexp-alist-alist
<span id="L618" class="ln">   618</span>	                 &#39;(go-test . (&#34;^\t+\\([^()\t\n]+\\):\\([0-9]+\\):? .*$&#34; 1 2)) t)))
<span id="L619" class="ln">   619</span>	
<span id="L620" class="ln">   620</span>	;;;###autoload
<span id="L621" class="ln">   621</span>	(add-to-list &#39;auto-mode-alist (cons &#34;\\.go\\&#39;&#34; &#39;go-mode))
<span id="L622" class="ln">   622</span>	
<span id="L623" class="ln">   623</span>	(defun go--apply-rcs-patch (patch-buffer)
<span id="L624" class="ln">   624</span>	  &#34;Apply an RCS-formatted diff from PATCH-BUFFER to the current
<span id="L625" class="ln">   625</span>	buffer.&#34;
<span id="L626" class="ln">   626</span>	  (let ((target-buffer (current-buffer))
<span id="L627" class="ln">   627</span>	        ;; Relative offset between buffer line numbers and line numbers
<span id="L628" class="ln">   628</span>	        ;; in patch.
<span id="L629" class="ln">   629</span>	        ;;
<span id="L630" class="ln">   630</span>	        ;; Line numbers in the patch are based on the source file, so
<span id="L631" class="ln">   631</span>	        ;; we have to keep an offset when making changes to the
<span id="L632" class="ln">   632</span>	        ;; buffer.
<span id="L633" class="ln">   633</span>	        ;;
<span id="L634" class="ln">   634</span>	        ;; Appending lines decrements the offset (possibly making it
<span id="L635" class="ln">   635</span>	        ;; negative), deleting lines increments it. This order
<span id="L636" class="ln">   636</span>	        ;; simplifies the forward-line invocations.
<span id="L637" class="ln">   637</span>	        (line-offset 0))
<span id="L638" class="ln">   638</span>	    (save-excursion
<span id="L639" class="ln">   639</span>	      (with-current-buffer patch-buffer
<span id="L640" class="ln">   640</span>	        (goto-char (point-min))
<span id="L641" class="ln">   641</span>	        (while (not (eobp))
<span id="L642" class="ln">   642</span>	          (unless (looking-at &#34;^\\([ad]\\)\\([0-9]+\\) \\([0-9]+\\)&#34;)
<span id="L643" class="ln">   643</span>	            (error &#34;invalid rcs patch or internal error in go--apply-rcs-patch&#34;))
<span id="L644" class="ln">   644</span>	          (forward-line)
<span id="L645" class="ln">   645</span>	          (let ((action (match-string 1))
<span id="L646" class="ln">   646</span>	                (from (string-to-number (match-string 2)))
<span id="L647" class="ln">   647</span>	                (len  (string-to-number (match-string 3))))
<span id="L648" class="ln">   648</span>	            (cond
<span id="L649" class="ln">   649</span>	             ((equal action &#34;a&#34;)
<span id="L650" class="ln">   650</span>	              (let ((start (point)))
<span id="L651" class="ln">   651</span>	                (forward-line len)
<span id="L652" class="ln">   652</span>	                (let ((text (buffer-substring start (point))))
<span id="L653" class="ln">   653</span>	                  (with-current-buffer target-buffer
<span id="L654" class="ln">   654</span>	                    (decf line-offset len)
<span id="L655" class="ln">   655</span>	                    (goto-char (point-min))
<span id="L656" class="ln">   656</span>	                    (forward-line (- from len line-offset))
<span id="L657" class="ln">   657</span>	                    (insert text)))))
<span id="L658" class="ln">   658</span>	             ((equal action &#34;d&#34;)
<span id="L659" class="ln">   659</span>	              (with-current-buffer target-buffer
<span id="L660" class="ln">   660</span>	                (go--goto-line (- from line-offset))
<span id="L661" class="ln">   661</span>	                (incf line-offset len)
<span id="L662" class="ln">   662</span>	                (go--delete-whole-line len)))
<span id="L663" class="ln">   663</span>	             (t
<span id="L664" class="ln">   664</span>	              (error &#34;invalid rcs patch or internal error in go--apply-rcs-patch&#34;)))))))))
<span id="L665" class="ln">   665</span>	
<span id="L666" class="ln">   666</span>	(defun gofmt ()
<span id="L667" class="ln">   667</span>	  &#34;Formats the current buffer according to the gofmt tool.&#34;
<span id="L668" class="ln">   668</span>	
<span id="L669" class="ln">   669</span>	  (interactive)
<span id="L670" class="ln">   670</span>	  (let ((tmpfile (make-temp-file &#34;gofmt&#34; nil &#34;.go&#34;))
<span id="L671" class="ln">   671</span>	        (patchbuf (get-buffer-create &#34;*Gofmt patch*&#34;))
<span id="L672" class="ln">   672</span>	        (errbuf (get-buffer-create &#34;*Gofmt Errors*&#34;))
<span id="L673" class="ln">   673</span>	        (coding-system-for-read &#39;utf-8)
<span id="L674" class="ln">   674</span>	        (coding-system-for-write &#39;utf-8))
<span id="L675" class="ln">   675</span>	
<span id="L676" class="ln">   676</span>	    (with-current-buffer errbuf
<span id="L677" class="ln">   677</span>	      (setq buffer-read-only nil)
<span id="L678" class="ln">   678</span>	      (erase-buffer))
<span id="L679" class="ln">   679</span>	    (with-current-buffer patchbuf
<span id="L680" class="ln">   680</span>	      (erase-buffer))
<span id="L681" class="ln">   681</span>	
<span id="L682" class="ln">   682</span>	    (write-region nil nil tmpfile)
<span id="L683" class="ln">   683</span>	
<span id="L684" class="ln">   684</span>	    ;; We&#39;re using errbuf for the mixed stdout and stderr output. This
<span id="L685" class="ln">   685</span>	    ;; is not an issue because gofmt -w does not produce any stdout
<span id="L686" class="ln">   686</span>	    ;; output in case of success.
<span id="L687" class="ln">   687</span>	    (if (zerop (call-process gofmt-command nil errbuf nil &#34;-w&#34; tmpfile))
<span id="L688" class="ln">   688</span>	        (if (zerop (call-process-region (point-min) (point-max) &#34;diff&#34; nil patchbuf nil &#34;-n&#34; &#34;-&#34; tmpfile))
<span id="L689" class="ln">   689</span>	            (progn
<span id="L690" class="ln">   690</span>	              (kill-buffer errbuf)
<span id="L691" class="ln">   691</span>	              (message &#34;Buffer is already gofmted&#34;))
<span id="L692" class="ln">   692</span>	          (go--apply-rcs-patch patchbuf)
<span id="L693" class="ln">   693</span>	          (kill-buffer errbuf)
<span id="L694" class="ln">   694</span>	          (message &#34;Applied gofmt&#34;))
<span id="L695" class="ln">   695</span>	      (message &#34;Could not apply gofmt. Check errors for details&#34;)
<span id="L696" class="ln">   696</span>	      (gofmt--process-errors (buffer-file-name) tmpfile errbuf))
<span id="L697" class="ln">   697</span>	
<span id="L698" class="ln">   698</span>	    (kill-buffer patchbuf)
<span id="L699" class="ln">   699</span>	    (delete-file tmpfile)))
<span id="L700" class="ln">   700</span>	
<span id="L701" class="ln">   701</span>	
<span id="L702" class="ln">   702</span>	(defun gofmt--process-errors (filename tmpfile errbuf)
<span id="L703" class="ln">   703</span>	  ;; Convert the gofmt stderr to something understood by the compilation mode.
<span id="L704" class="ln">   704</span>	  (with-current-buffer errbuf
<span id="L705" class="ln">   705</span>	    (goto-char (point-min))
<span id="L706" class="ln">   706</span>	    (insert &#34;gofmt errors:\n&#34;)
<span id="L707" class="ln">   707</span>	    (while (search-forward-regexp (concat &#34;^\\(&#34; (regexp-quote tmpfile) &#34;\\):&#34;) nil t)
<span id="L708" class="ln">   708</span>	      (replace-match (file-name-nondirectory filename) t t nil 1))
<span id="L709" class="ln">   709</span>	    (compilation-mode)
<span id="L710" class="ln">   710</span>	    (display-buffer errbuf)))
<span id="L711" class="ln">   711</span>	
<span id="L712" class="ln">   712</span>	;;;###autoload
<span id="L713" class="ln">   713</span>	(defun gofmt-before-save ()
<span id="L714" class="ln">   714</span>	  &#34;Add this to .emacs to run gofmt on the current buffer when saving:
<span id="L715" class="ln">   715</span>	 (add-hook &#39;before-save-hook &#39;gofmt-before-save).
<span id="L716" class="ln">   716</span>	
<span id="L717" class="ln">   717</span>	Note that this will cause go-mode to get loaded the first time
<span id="L718" class="ln">   718</span>	you save any file, kind of defeating the point of autoloading.&#34;
<span id="L719" class="ln">   719</span>	
<span id="L720" class="ln">   720</span>	  (interactive)
<span id="L721" class="ln">   721</span>	  (when (eq major-mode &#39;go-mode) (gofmt)))
<span id="L722" class="ln">   722</span>	
<span id="L723" class="ln">   723</span>	(defun godoc--read-query ()
<span id="L724" class="ln">   724</span>	  &#34;Read a godoc query from the minibuffer.&#34;
<span id="L725" class="ln">   725</span>	  ;; Compute the default query as the symbol under the cursor.
<span id="L726" class="ln">   726</span>	  ;; TODO: This does the wrong thing for e.g. multipart.NewReader (it only grabs
<span id="L727" class="ln">   727</span>	  ;; half) but I see no way to disambiguate that from e.g. foobar.SomeMethod.
<span id="L728" class="ln">   728</span>	  (let* ((bounds (bounds-of-thing-at-point &#39;symbol))
<span id="L729" class="ln">   729</span>	         (symbol (if bounds
<span id="L730" class="ln">   730</span>	                     (buffer-substring-no-properties (car bounds)
<span id="L731" class="ln">   731</span>	                                                     (cdr bounds)))))
<span id="L732" class="ln">   732</span>	    (completing-read (if symbol
<span id="L733" class="ln">   733</span>	                         (format &#34;godoc (default %s): &#34; symbol)
<span id="L734" class="ln">   734</span>	                       &#34;godoc: &#34;)
<span id="L735" class="ln">   735</span>	                     (go--old-completion-list-style (go-packages)) nil nil nil &#39;go-godoc-history symbol)))
<span id="L736" class="ln">   736</span>	
<span id="L737" class="ln">   737</span>	(defun godoc--get-buffer (query)
<span id="L738" class="ln">   738</span>	  &#34;Get an empty buffer for a godoc query.&#34;
<span id="L739" class="ln">   739</span>	  (let* ((buffer-name (concat &#34;*godoc &#34; query &#34;*&#34;))
<span id="L740" class="ln">   740</span>	         (buffer (get-buffer buffer-name)))
<span id="L741" class="ln">   741</span>	    ;; Kill the existing buffer if it already exists.
<span id="L742" class="ln">   742</span>	    (when buffer (kill-buffer buffer))
<span id="L743" class="ln">   743</span>	    (get-buffer-create buffer-name)))
<span id="L744" class="ln">   744</span>	
<span id="L745" class="ln">   745</span>	(defun godoc--buffer-sentinel (proc event)
<span id="L746" class="ln">   746</span>	  &#34;Sentinel function run when godoc command completes.&#34;
<span id="L747" class="ln">   747</span>	  (with-current-buffer (process-buffer proc)
<span id="L748" class="ln">   748</span>	    (cond ((string= event &#34;finished\n&#34;)  ;; Successful exit.
<span id="L749" class="ln">   749</span>	           (goto-char (point-min))
<span id="L750" class="ln">   750</span>	           (view-mode 1)
<span id="L751" class="ln">   751</span>	           (display-buffer (current-buffer) t))
<span id="L752" class="ln">   752</span>	          ((/= (process-exit-status proc) 0)  ;; Error exit.
<span id="L753" class="ln">   753</span>	           (let ((output (buffer-string)))
<span id="L754" class="ln">   754</span>	             (kill-buffer (current-buffer))
<span id="L755" class="ln">   755</span>	             (message (concat &#34;godoc: &#34; output)))))))
<span id="L756" class="ln">   756</span>	
<span id="L757" class="ln">   757</span>	;;;###autoload
<span id="L758" class="ln">   758</span>	(defun godoc (query)
<span id="L759" class="ln">   759</span>	  &#34;Show go documentation for a query, much like M-x man.&#34;
<span id="L760" class="ln">   760</span>	  (interactive (list (godoc--read-query)))
<span id="L761" class="ln">   761</span>	  (unless (string= query &#34;&#34;)
<span id="L762" class="ln">   762</span>	    (set-process-sentinel
<span id="L763" class="ln">   763</span>	     (start-process-shell-command &#34;godoc&#34; (godoc--get-buffer query)
<span id="L764" class="ln">   764</span>	                                  (concat &#34;godoc &#34; query))
<span id="L765" class="ln">   765</span>	     &#39;godoc--buffer-sentinel)
<span id="L766" class="ln">   766</span>	    nil))
<span id="L767" class="ln">   767</span>	
<span id="L768" class="ln">   768</span>	(defun go-goto-imports ()
<span id="L769" class="ln">   769</span>	  &#34;Move point to the block of imports.
<span id="L770" class="ln">   770</span>	
<span id="L771" class="ln">   771</span>	If using
<span id="L772" class="ln">   772</span>	
<span id="L773" class="ln">   773</span>	  import (
<span id="L774" class="ln">   774</span>	    \&#34;foo\&#34;
<span id="L775" class="ln">   775</span>	    \&#34;bar\&#34;
<span id="L776" class="ln">   776</span>	  )
<span id="L777" class="ln">   777</span>	
<span id="L778" class="ln">   778</span>	it will move point directly behind the last import.
<span id="L779" class="ln">   779</span>	
<span id="L780" class="ln">   780</span>	If using
<span id="L781" class="ln">   781</span>	
<span id="L782" class="ln">   782</span>	  import \&#34;foo\&#34;
<span id="L783" class="ln">   783</span>	  import \&#34;bar\&#34;
<span id="L784" class="ln">   784</span>	
<span id="L785" class="ln">   785</span>	it will move point to the next line after the last import.
<span id="L786" class="ln">   786</span>	
<span id="L787" class="ln">   787</span>	If no imports can be found, point will be moved after the package
<span id="L788" class="ln">   788</span>	declaration.&#34;
<span id="L789" class="ln">   789</span>	  (interactive)
<span id="L790" class="ln">   790</span>	  ;; FIXME if there&#39;s a block-commented import before the real
<span id="L791" class="ln">   791</span>	  ;; imports, we&#39;ll jump to that one.
<span id="L792" class="ln">   792</span>	
<span id="L793" class="ln">   793</span>	  ;; Generally, this function isn&#39;t very forgiving. it&#39;ll bark on
<span id="L794" class="ln">   794</span>	  ;; extra whitespace. It works well for clean code.
<span id="L795" class="ln">   795</span>	  (let ((old-point (point)))
<span id="L796" class="ln">   796</span>	    (goto-char (point-min))
<span id="L797" class="ln">   797</span>	    (cond
<span id="L798" class="ln">   798</span>	     ((re-search-forward &#34;^import ()&#34; nil t)
<span id="L799" class="ln">   799</span>	      (backward-char 1)
<span id="L800" class="ln">   800</span>	      &#39;block-empty)
<span id="L801" class="ln">   801</span>	     ((re-search-forward &#34;^import ([^)]+)&#34; nil t)
<span id="L802" class="ln">   802</span>	      (backward-char 2)
<span id="L803" class="ln">   803</span>	      &#39;block)
<span id="L804" class="ln">   804</span>	     ((re-search-forward &#34;\\(^import \\([^\&#34;]+ \\)?\&#34;[^\&#34;]+\&#34;\n?\\)+&#34; nil t)
<span id="L805" class="ln">   805</span>	      &#39;single)
<span id="L806" class="ln">   806</span>	     ((re-search-forward &#34;^[[:space:]\n]*package .+?\n&#34; nil t)
<span id="L807" class="ln">   807</span>	      (message &#34;No imports found, moving point after package declaration&#34;)
<span id="L808" class="ln">   808</span>	      &#39;none)
<span id="L809" class="ln">   809</span>	     (t
<span id="L810" class="ln">   810</span>	      (goto-char old-point)
<span id="L811" class="ln">   811</span>	      (message &#34;No imports or package declaration found. Is this really a Go file?&#34;)
<span id="L812" class="ln">   812</span>	      &#39;fail))))
<span id="L813" class="ln">   813</span>	
<span id="L814" class="ln">   814</span>	(defun go-play-buffer ()
<span id="L815" class="ln">   815</span>	  &#34;Like `go-play-region&#39;, but acts on the entire buffer.&#34;
<span id="L816" class="ln">   816</span>	  (interactive)
<span id="L817" class="ln">   817</span>	  (go-play-region (point-min) (point-max)))
<span id="L818" class="ln">   818</span>	
<span id="L819" class="ln">   819</span>	(defun go-play-region (start end)
<span id="L820" class="ln">   820</span>	  &#34;Send the region to the Playground and stores the resulting
<span id="L821" class="ln">   821</span>	link in the kill ring.&#34;
<span id="L822" class="ln">   822</span>	  (interactive &#34;r&#34;)
<span id="L823" class="ln">   823</span>	  (let* ((url-request-method &#34;POST&#34;)
<span id="L824" class="ln">   824</span>	         (url-request-extra-headers
<span id="L825" class="ln">   825</span>	          &#39;((&#34;Content-Type&#34; . &#34;application/x-www-form-urlencoded&#34;)))
<span id="L826" class="ln">   826</span>	         (url-request-data
<span id="L827" class="ln">   827</span>	          (encode-coding-string
<span id="L828" class="ln">   828</span>	           (buffer-substring-no-properties start end)
<span id="L829" class="ln">   829</span>	           &#39;utf-8))
<span id="L830" class="ln">   830</span>	         (content-buf (url-retrieve
<span id="L831" class="ln">   831</span>	                       &#34;http://play.golang.org/share&#34;
<span id="L832" class="ln">   832</span>	                       (lambda (arg)
<span id="L833" class="ln">   833</span>	                         (cond
<span id="L834" class="ln">   834</span>	                          ((equal :error (car arg))
<span id="L835" class="ln">   835</span>	                           (signal &#39;go-play-error (cdr arg)))
<span id="L836" class="ln">   836</span>	                          (t
<span id="L837" class="ln">   837</span>	                           (re-search-forward &#34;\n\n&#34;)
<span id="L838" class="ln">   838</span>	                           (kill-new (format &#34;http://play.golang.org/p/%s&#34; (buffer-substring (point) (point-max))))
<span id="L839" class="ln">   839</span>	                           (message &#34;http://play.golang.org/p/%s&#34; (buffer-substring (point) (point-max)))))))))))
<span id="L840" class="ln">   840</span>	
<span id="L841" class="ln">   841</span>	;;;###autoload
<span id="L842" class="ln">   842</span>	(defun go-download-play (url)
<span id="L843" class="ln">   843</span>	  &#34;Downloads a paste from the playground and inserts it in a Go
<span id="L844" class="ln">   844</span>	buffer. Tries to look for a URL at point.&#34;
<span id="L845" class="ln">   845</span>	  (interactive (list (read-from-minibuffer &#34;Playground URL: &#34; (ffap-url-p (ffap-string-at-point &#39;url)))))
<span id="L846" class="ln">   846</span>	  (with-current-buffer
<span id="L847" class="ln">   847</span>	      (let ((url-request-method &#34;GET&#34;) url-request-data url-request-extra-headers)
<span id="L848" class="ln">   848</span>	        (url-retrieve-synchronously (concat url &#34;.go&#34;)))
<span id="L849" class="ln">   849</span>	    (let ((buffer (generate-new-buffer (concat (car (last (split-string url &#34;/&#34;))) &#34;.go&#34;))))
<span id="L850" class="ln">   850</span>	      (goto-char (point-min))
<span id="L851" class="ln">   851</span>	      (re-search-forward &#34;\n\n&#34;)
<span id="L852" class="ln">   852</span>	      (copy-to-buffer buffer (point) (point-max))
<span id="L853" class="ln">   853</span>	      (kill-buffer)
<span id="L854" class="ln">   854</span>	      (with-current-buffer buffer
<span id="L855" class="ln">   855</span>	        (go-mode)
<span id="L856" class="ln">   856</span>	        (switch-to-buffer buffer)))))
<span id="L857" class="ln">   857</span>	
<span id="L858" class="ln">   858</span>	(defun go-propertize-syntax (start end)
<span id="L859" class="ln">   859</span>	  (save-excursion
<span id="L860" class="ln">   860</span>	    (goto-char start)
<span id="L861" class="ln">   861</span>	    (while (search-forward &#34;\\&#34; end t)
<span id="L862" class="ln">   862</span>	      (put-text-property (1- (point)) (point) &#39;syntax-table (if (= (char-after) ?`) &#39;(1) &#39;(9))))))
<span id="L863" class="ln">   863</span>	
<span id="L864" class="ln">   864</span>	(defun go-import-add (arg import)
<span id="L865" class="ln">   865</span>	  &#34;Add a new import to the list of imports.
<span id="L866" class="ln">   866</span>	
<span id="L867" class="ln">   867</span>	When called with a prefix argument asks for an alternative name
<span id="L868" class="ln">   868</span>	to import the package as.
<span id="L869" class="ln">   869</span>	
<span id="L870" class="ln">   870</span>	If no list exists yet, one will be created if possible.
<span id="L871" class="ln">   871</span>	
<span id="L872" class="ln">   872</span>	If an identical import has been commented, it will be
<span id="L873" class="ln">   873</span>	uncommented, otherwise a new import will be added.&#34;
<span id="L874" class="ln">   874</span>	
<span id="L875" class="ln">   875</span>	  ;; - If there&#39;s a matching `// import &#34;foo&#34;`, uncomment it
<span id="L876" class="ln">   876</span>	  ;; - If we&#39;re in an import() block and there&#39;s a matching `&#34;foo&#34;`, uncomment it
<span id="L877" class="ln">   877</span>	  ;; - Otherwise add a new import, with the appropriate syntax
<span id="L878" class="ln">   878</span>	  (interactive
<span id="L879" class="ln">   879</span>	   (list
<span id="L880" class="ln">   880</span>	    current-prefix-arg
<span id="L881" class="ln">   881</span>	    (replace-regexp-in-string &#34;^[\&#34;&#39;]\\|[\&#34;&#39;]$&#34; &#34;&#34; (completing-read &#34;Package: &#34; (go--old-completion-list-style (go-packages))))))
<span id="L882" class="ln">   882</span>	  (save-excursion
<span id="L883" class="ln">   883</span>	    (let (as line import-start)
<span id="L884" class="ln">   884</span>	      (if arg
<span id="L885" class="ln">   885</span>	          (setq as (read-from-minibuffer &#34;Import as: &#34;)))
<span id="L886" class="ln">   886</span>	      (if as
<span id="L887" class="ln">   887</span>	          (setq line (format &#34;%s \&#34;%s\&#34;&#34; as import))
<span id="L888" class="ln">   888</span>	        (setq line (format &#34;\&#34;%s\&#34;&#34; import)))
<span id="L889" class="ln">   889</span>	
<span id="L890" class="ln">   890</span>	      (goto-char (point-min))
<span id="L891" class="ln">   891</span>	      (if (re-search-forward (concat &#34;^[[:space:]]*//[[:space:]]*import &#34; line &#34;$&#34;) nil t)
<span id="L892" class="ln">   892</span>	          (uncomment-region (line-beginning-position) (line-end-position))
<span id="L893" class="ln">   893</span>	        (case (go-goto-imports)
<span id="L894" class="ln">   894</span>	          (&#39;fail (message &#34;Could not find a place to add import.&#34;))
<span id="L895" class="ln">   895</span>	          (&#39;block-empty
<span id="L896" class="ln">   896</span>	           (insert &#34;\n\t&#34; line &#34;\n&#34;))
<span id="L897" class="ln">   897</span>	          (&#39;block
<span id="L898" class="ln">   898</span>	              (save-excursion
<span id="L899" class="ln">   899</span>	                (re-search-backward &#34;^import (&#34;)
<span id="L900" class="ln">   900</span>	                (setq import-start (point)))
<span id="L901" class="ln">   901</span>	            (if (re-search-backward (concat &#34;^[[:space:]]*//[[:space:]]*&#34; line &#34;$&#34;)  import-start t)
<span id="L902" class="ln">   902</span>	                (uncomment-region (line-beginning-position) (line-end-position))
<span id="L903" class="ln">   903</span>	              (insert &#34;\n\t&#34; line)))
<span id="L904" class="ln">   904</span>	          (&#39;single (insert &#34;import &#34; line &#34;\n&#34;))
<span id="L905" class="ln">   905</span>	          (&#39;none (insert &#34;\nimport (\n\t&#34; line &#34;\n)\n&#34;)))))))
<span id="L906" class="ln">   906</span>	
<span id="L907" class="ln">   907</span>	(defun go-root-and-paths ()
<span id="L908" class="ln">   908</span>	  (let* ((output (split-string (shell-command-to-string (concat go-command &#34; env GOROOT GOPATH&#34;))
<span id="L909" class="ln">   909</span>	                               &#34;\n&#34;))
<span id="L910" class="ln">   910</span>	         (root (car output))
<span id="L911" class="ln">   911</span>	         (paths (split-string (cadr output) &#34;:&#34;)))
<span id="L912" class="ln">   912</span>	    (append (list root) paths)))
<span id="L913" class="ln">   913</span>	
<span id="L914" class="ln">   914</span>	(defun go--string-prefix-p (s1 s2 &amp;optional ignore-case)
<span id="L915" class="ln">   915</span>	  &#34;Return non-nil if S1 is a prefix of S2.
<span id="L916" class="ln">   916</span>	If IGNORE-CASE is non-nil, the comparison is case-insensitive.&#34;
<span id="L917" class="ln">   917</span>	  (eq t (compare-strings s1 nil nil
<span id="L918" class="ln">   918</span>	                         s2 0 (length s1) ignore-case)))
<span id="L919" class="ln">   919</span>	
<span id="L920" class="ln">   920</span>	(defun go--directory-dirs (dir)
<span id="L921" class="ln">   921</span>	  &#34;Recursively return all subdirectories in DIR.&#34;
<span id="L922" class="ln">   922</span>	  (if (file-directory-p dir)
<span id="L923" class="ln">   923</span>	      (let ((dir (directory-file-name dir))
<span id="L924" class="ln">   924</span>	            (dirs &#39;())
<span id="L925" class="ln">   925</span>	            (files (directory-files dir nil nil t)))
<span id="L926" class="ln">   926</span>	        (dolist (file files)
<span id="L927" class="ln">   927</span>	          (unless (member file &#39;(&#34;.&#34; &#34;..&#34;))
<span id="L928" class="ln">   928</span>	            (let ((file (concat dir &#34;/&#34; file)))
<span id="L929" class="ln">   929</span>	              (if (file-directory-p file)
<span id="L930" class="ln">   930</span>	                  (setq dirs (append (cons file
<span id="L931" class="ln">   931</span>	                                           (go--directory-dirs file))
<span id="L932" class="ln">   932</span>	                                     dirs))))))
<span id="L933" class="ln">   933</span>	        dirs)
<span id="L934" class="ln">   934</span>	    &#39;()))
<span id="L935" class="ln">   935</span>	
<span id="L936" class="ln">   936</span>	
<span id="L937" class="ln">   937</span>	(defun go-packages ()
<span id="L938" class="ln">   938</span>	  (sort
<span id="L939" class="ln">   939</span>	   (delete-dups
<span id="L940" class="ln">   940</span>	    (mapcan
<span id="L941" class="ln">   941</span>	     (lambda (topdir)
<span id="L942" class="ln">   942</span>	       (let ((pkgdir (concat topdir &#34;/pkg/&#34;)))
<span id="L943" class="ln">   943</span>	         (mapcan (lambda (dir)
<span id="L944" class="ln">   944</span>	                   (mapcar (lambda (file)
<span id="L945" class="ln">   945</span>	                             (let ((sub (substring file (length pkgdir) -2)))
<span id="L946" class="ln">   946</span>	                               (unless (or (go--string-prefix-p &#34;obj/&#34; sub) (go--string-prefix-p &#34;tool/&#34; sub))
<span id="L947" class="ln">   947</span>	                                 (mapconcat #&#39;identity (cdr (split-string sub &#34;/&#34;)) &#34;/&#34;))))
<span id="L948" class="ln">   948</span>	                           (if (file-directory-p dir)
<span id="L949" class="ln">   949</span>	                               (directory-files dir t &#34;\\.a$&#34;))))
<span id="L950" class="ln">   950</span>	                 (if (file-directory-p pkgdir)
<span id="L951" class="ln">   951</span>	                     (go--directory-dirs pkgdir)))))
<span id="L952" class="ln">   952</span>	     (go-root-and-paths)))
<span id="L953" class="ln">   953</span>	   #&#39;string&lt;))
<span id="L954" class="ln">   954</span>	
<span id="L955" class="ln">   955</span>	(defun go-unused-imports-lines ()
<span id="L956" class="ln">   956</span>	  ;; FIXME Technically, -o /dev/null fails in quite some cases (on
<span id="L957" class="ln">   957</span>	  ;; Windows, when compiling from within GOPATH). Practically,
<span id="L958" class="ln">   958</span>	  ;; however, it has the same end result: There won&#39;t be a
<span id="L959" class="ln">   959</span>	  ;; compiled binary/archive, and we&#39;ll get our import errors when
<span id="L960" class="ln">   960</span>	  ;; there are any.
<span id="L961" class="ln">   961</span>	  (reverse (remove nil
<span id="L962" class="ln">   962</span>	                   (mapcar
<span id="L963" class="ln">   963</span>	                    (lambda (line)
<span id="L964" class="ln">   964</span>	                      (if (string-match &#34;^\\(.+\\):\\([[:digit:]]+\\): imported and not used: \&#34;.+\&#34;.*$&#34; line)
<span id="L965" class="ln">   965</span>	                          (if (string= (file-truename (match-string 1 line)) (file-truename buffer-file-name))
<span id="L966" class="ln">   966</span>	                              (string-to-number (match-string 2 line)))))
<span id="L967" class="ln">   967</span>	                    (split-string (shell-command-to-string
<span id="L968" class="ln">   968</span>	                                   (concat go-command
<span id="L969" class="ln">   969</span>	                                           (if (string-match &#34;_test\.go$&#34; buffer-file-truename)
<span id="L970" class="ln">   970</span>	                                               &#34; test -c&#34;
<span id="L971" class="ln">   971</span>	                                             &#34; build -o /dev/null&#34;))) &#34;\n&#34;)))))
<span id="L972" class="ln">   972</span>	
<span id="L973" class="ln">   973</span>	(defun go-remove-unused-imports (arg)
<span id="L974" class="ln">   974</span>	  &#34;Removes all unused imports. If ARG is non-nil, unused imports
<span id="L975" class="ln">   975</span>	will be commented, otherwise they will be removed completely.&#34;
<span id="L976" class="ln">   976</span>	  (interactive &#34;P&#34;)
<span id="L977" class="ln">   977</span>	  (save-excursion
<span id="L978" class="ln">   978</span>	    (let ((cur-buffer (current-buffer)) flymake-state lines)
<span id="L979" class="ln">   979</span>	      (when (boundp &#39;flymake-mode)
<span id="L980" class="ln">   980</span>	        (setq flymake-state flymake-mode)
<span id="L981" class="ln">   981</span>	        (flymake-mode-off))
<span id="L982" class="ln">   982</span>	      (save-some-buffers nil (lambda () (equal cur-buffer (current-buffer))))
<span id="L983" class="ln">   983</span>	      (if (buffer-modified-p)
<span id="L984" class="ln">   984</span>	          (message &#34;Cannot operate on unsaved buffer&#34;)
<span id="L985" class="ln">   985</span>	        (setq lines (go-unused-imports-lines))
<span id="L986" class="ln">   986</span>	        (dolist (import lines)
<span id="L987" class="ln">   987</span>	          (go--goto-line import)
<span id="L988" class="ln">   988</span>	          (beginning-of-line)
<span id="L989" class="ln">   989</span>	          (if arg
<span id="L990" class="ln">   990</span>	              (comment-region (line-beginning-position) (line-end-position))
<span id="L991" class="ln">   991</span>	            (go--delete-whole-line)))
<span id="L992" class="ln">   992</span>	        (message &#34;Removed %d imports&#34; (length lines)))
<span id="L993" class="ln">   993</span>	      (if flymake-state (flymake-mode-on)))))
<span id="L994" class="ln">   994</span>	
<span id="L995" class="ln">   995</span>	(defun godef--find-file-line-column (specifier other-window)
<span id="L996" class="ln">   996</span>	  &#34;Given a file name in the format of `filename:line:column&#39;,
<span id="L997" class="ln">   997</span>	visit FILENAME and go to line LINE and column COLUMN.&#34;
<span id="L998" class="ln">   998</span>	  (if (not (string-match &#34;\\(.+\\):\\([0-9]+\\):\\([0-9]+\\)&#34; specifier))
<span id="L999" class="ln">   999</span>	      ;; We&#39;ve only been given a directory name
<span id="L1000" class="ln">  1000</span>	      (funcall (if other-window #&#39;find-file-other-window #&#39;find-file) specifier)
<span id="L1001" class="ln">  1001</span>	    (let ((filename (match-string 1 specifier))
<span id="L1002" class="ln">  1002</span>	          (line (string-to-number (match-string 2 specifier)))
<span id="L1003" class="ln">  1003</span>	          (column (string-to-number (match-string 3 specifier))))
<span id="L1004" class="ln">  1004</span>	      (with-current-buffer (funcall (if other-window #&#39;find-file-other-window #&#39;find-file) filename)
<span id="L1005" class="ln">  1005</span>	        (go--goto-line line)
<span id="L1006" class="ln">  1006</span>	        (beginning-of-line)
<span id="L1007" class="ln">  1007</span>	        (forward-char (1- column))
<span id="L1008" class="ln">  1008</span>	        (if (buffer-modified-p)
<span id="L1009" class="ln">  1009</span>	            (message &#34;Buffer is modified, file position might not have been correct&#34;))))))
<span id="L1010" class="ln">  1010</span>	
<span id="L1011" class="ln">  1011</span>	(defun godef--call (point)
<span id="L1012" class="ln">  1012</span>	  &#34;Call godef, acquiring definition position and expression
<span id="L1013" class="ln">  1013</span>	description at POINT.&#34;
<span id="L1014" class="ln">  1014</span>	  (if (go--xemacs-p)
<span id="L1015" class="ln">  1015</span>	      (error &#34;godef does not reliably work in XEmacs, expect bad results&#34;))
<span id="L1016" class="ln">  1016</span>	  (if (not (buffer-file-name (go--coverage-origin-buffer)))
<span id="L1017" class="ln">  1017</span>	      (error &#34;Cannot use godef on a buffer without a file name&#34;)
<span id="L1018" class="ln">  1018</span>	    (let ((outbuf (get-buffer-create &#34;*godef*&#34;)))
<span id="L1019" class="ln">  1019</span>	      (with-current-buffer outbuf
<span id="L1020" class="ln">  1020</span>	        (erase-buffer))
<span id="L1021" class="ln">  1021</span>	      (call-process-region (point-min)
<span id="L1022" class="ln">  1022</span>	                           (point-max)
<span id="L1023" class="ln">  1023</span>	                           &#34;godef&#34;
<span id="L1024" class="ln">  1024</span>	                           nil
<span id="L1025" class="ln">  1025</span>	                           outbuf
<span id="L1026" class="ln">  1026</span>	                           nil
<span id="L1027" class="ln">  1027</span>	                           &#34;-i&#34;
<span id="L1028" class="ln">  1028</span>	                           &#34;-t&#34;
<span id="L1029" class="ln">  1029</span>	                           &#34;-f&#34;
<span id="L1030" class="ln">  1030</span>	                           (file-truename (buffer-file-name (go--coverage-origin-buffer)))
<span id="L1031" class="ln">  1031</span>	                           &#34;-o&#34;
<span id="L1032" class="ln">  1032</span>	                           (number-to-string (go--position-bytes point)))
<span id="L1033" class="ln">  1033</span>	      (with-current-buffer outbuf
<span id="L1034" class="ln">  1034</span>	        (split-string (buffer-substring-no-properties (point-min) (point-max)) &#34;\n&#34;)))))
<span id="L1035" class="ln">  1035</span>	
<span id="L1036" class="ln">  1036</span>	(defun godef-describe (point)
<span id="L1037" class="ln">  1037</span>	  &#34;Describe the expression at POINT.&#34;
<span id="L1038" class="ln">  1038</span>	  (interactive &#34;d&#34;)
<span id="L1039" class="ln">  1039</span>	  (condition-case nil
<span id="L1040" class="ln">  1040</span>	      (let ((description (cdr (butlast (godef--call point) 1))))
<span id="L1041" class="ln">  1041</span>	        (if (not description)
<span id="L1042" class="ln">  1042</span>	            (message &#34;No description found for expression at point&#34;)
<span id="L1043" class="ln">  1043</span>	          (message &#34;%s&#34; (mapconcat #&#39;identity description &#34;\n&#34;))))
<span id="L1044" class="ln">  1044</span>	    (file-error (message &#34;Could not run godef binary&#34;))))
<span id="L1045" class="ln">  1045</span>	
<span id="L1046" class="ln">  1046</span>	(defun godef-jump (point &amp;optional other-window)
<span id="L1047" class="ln">  1047</span>	  &#34;Jump to the definition of the expression at POINT.&#34;
<span id="L1048" class="ln">  1048</span>	  (interactive &#34;d&#34;)
<span id="L1049" class="ln">  1049</span>	  (condition-case nil
<span id="L1050" class="ln">  1050</span>	      (let ((file (car (godef--call point))))
<span id="L1051" class="ln">  1051</span>	        (cond
<span id="L1052" class="ln">  1052</span>	         ((string= &#34;-&#34; file)
<span id="L1053" class="ln">  1053</span>	          (message &#34;godef: expression is not defined anywhere&#34;))
<span id="L1054" class="ln">  1054</span>	         ((string= &#34;godef: no identifier found&#34; file)
<span id="L1055" class="ln">  1055</span>	          (message &#34;%s&#34; file))
<span id="L1056" class="ln">  1056</span>	         ((go--string-prefix-p &#34;godef: no declaration found for &#34; file)
<span id="L1057" class="ln">  1057</span>	          (message &#34;%s&#34; file))
<span id="L1058" class="ln">  1058</span>	         ((go--string-prefix-p &#34;error finding import path for &#34; file)
<span id="L1059" class="ln">  1059</span>	          (message &#34;%s&#34; file))
<span id="L1060" class="ln">  1060</span>	         (t
<span id="L1061" class="ln">  1061</span>	          (push-mark)
<span id="L1062" class="ln">  1062</span>	          (ring-insert find-tag-marker-ring (point-marker))
<span id="L1063" class="ln">  1063</span>	          (godef--find-file-line-column file other-window))))
<span id="L1064" class="ln">  1064</span>	    (file-error (message &#34;Could not run godef binary&#34;))))
<span id="L1065" class="ln">  1065</span>	
<span id="L1066" class="ln">  1066</span>	(defun godef-jump-other-window (point)
<span id="L1067" class="ln">  1067</span>	  (interactive &#34;d&#34;)
<span id="L1068" class="ln">  1068</span>	  (godef-jump point t))
<span id="L1069" class="ln">  1069</span>	
<span id="L1070" class="ln">  1070</span>	(defun go--goto-line (line)
<span id="L1071" class="ln">  1071</span>	  (goto-char (point-min))
<span id="L1072" class="ln">  1072</span>	  (forward-line (1- line)))
<span id="L1073" class="ln">  1073</span>	
<span id="L1074" class="ln">  1074</span>	(defun go--line-column-to-point (line column)
<span id="L1075" class="ln">  1075</span>	  (save-excursion
<span id="L1076" class="ln">  1076</span>	    (go--goto-line line)
<span id="L1077" class="ln">  1077</span>	    (forward-char (1- column))
<span id="L1078" class="ln">  1078</span>	    (point)))
<span id="L1079" class="ln">  1079</span>	
<span id="L1080" class="ln">  1080</span>	(defstruct go--covered
<span id="L1081" class="ln">  1081</span>	  start-line start-column end-line end-column covered count)
<span id="L1082" class="ln">  1082</span>	
<span id="L1083" class="ln">  1083</span>	(defun go--coverage-file ()
<span id="L1084" class="ln">  1084</span>	  &#34;Return the coverage file to use, either by reading it from the
<span id="L1085" class="ln">  1085</span>	current coverage buffer or by prompting for it.&#34;
<span id="L1086" class="ln">  1086</span>	  (if (boundp &#39;go--coverage-current-file-name)
<span id="L1087" class="ln">  1087</span>	      go--coverage-current-file-name
<span id="L1088" class="ln">  1088</span>	    (read-file-name &#34;Coverage file: &#34; nil nil t)))
<span id="L1089" class="ln">  1089</span>	
<span id="L1090" class="ln">  1090</span>	(defun go--coverage-origin-buffer ()
<span id="L1091" class="ln">  1091</span>	  &#34;Return the buffer to base the coverage on.&#34;
<span id="L1092" class="ln">  1092</span>	  (or (buffer-base-buffer) (current-buffer)))
<span id="L1093" class="ln">  1093</span>	
<span id="L1094" class="ln">  1094</span>	(defun go--coverage-face (count divisor)
<span id="L1095" class="ln">  1095</span>	  &#34;Return the intensity face for COUNT when using DIVISOR
<span id="L1096" class="ln">  1096</span>	to scale it to a range [0,10].
<span id="L1097" class="ln">  1097</span>	
<span id="L1098" class="ln">  1098</span>	DIVISOR scales the absolute cover count to values from 0 to 10.
<span id="L1099" class="ln">  1099</span>	For DIVISOR = 0 the count will always translate to 8.&#34;
<span id="L1100" class="ln">  1100</span>	  (let* ((norm (cond
<span id="L1101" class="ln">  1101</span>	                ((= count 0)
<span id="L1102" class="ln">  1102</span>	                 -0.1) ;; Uncovered code, set to -0.1 so n becomes 0.
<span id="L1103" class="ln">  1103</span>	                ((= divisor 0)
<span id="L1104" class="ln">  1104</span>	                 0.8) ;; covermode=set, set to 0.8 so n becomes 8.
<span id="L1105" class="ln">  1105</span>	                (t
<span id="L1106" class="ln">  1106</span>	                 (/ (log count) divisor))))
<span id="L1107" class="ln">  1107</span>	         (n (1+ (floor (* norm 9))))) ;; Convert normalized count [0,1] to intensity [0,10]
<span id="L1108" class="ln">  1108</span>	    (concat &#34;go-coverage-&#34; (number-to-string n))))
<span id="L1109" class="ln">  1109</span>	
<span id="L1110" class="ln">  1110</span>	(defun go--coverage-make-overlay (range divisor)
<span id="L1111" class="ln">  1111</span>	  &#34;Create a coverage overlay for a RANGE of covered/uncovered
<span id="L1112" class="ln">  1112</span>	code. Uses DIVISOR to scale absolute counts to a [0,10] scale.&#34;
<span id="L1113" class="ln">  1113</span>	  (let* ((count (go--covered-count range))
<span id="L1114" class="ln">  1114</span>	         (face (go--coverage-face count divisor))
<span id="L1115" class="ln">  1115</span>	         (ov (make-overlay (go--line-column-to-point (go--covered-start-line range)
<span id="L1116" class="ln">  1116</span>	                                                     (go--covered-start-column range))
<span id="L1117" class="ln">  1117</span>	                           (go--line-column-to-point (go--covered-end-line range)
<span id="L1118" class="ln">  1118</span>	                                                     (go--covered-end-column range)))))
<span id="L1119" class="ln">  1119</span>	
<span id="L1120" class="ln">  1120</span>	    (overlay-put ov &#39;face face)
<span id="L1121" class="ln">  1121</span>	    (overlay-put ov &#39;help-echo (format &#34;Count: %d&#34; count))))
<span id="L1122" class="ln">  1122</span>	
<span id="L1123" class="ln">  1123</span>	(defun go--coverage-clear-overlays ()
<span id="L1124" class="ln">  1124</span>	  &#34;Remove existing overlays and put a single untracked overlay
<span id="L1125" class="ln">  1125</span>	over the entire buffer.&#34;
<span id="L1126" class="ln">  1126</span>	  (remove-overlays)
<span id="L1127" class="ln">  1127</span>	  (overlay-put (make-overlay (point-min) (point-max))
<span id="L1128" class="ln">  1128</span>	               &#39;face
<span id="L1129" class="ln">  1129</span>	               &#39;go-coverage-untracked))
<span id="L1130" class="ln">  1130</span>	
<span id="L1131" class="ln">  1131</span>	(defun go--coverage-parse-file (coverage-file file-name)
<span id="L1132" class="ln">  1132</span>	  &#34;Parse COVERAGE-FILE and extract coverage information and
<span id="L1133" class="ln">  1133</span>	divisor for FILE-NAME.&#34;
<span id="L1134" class="ln">  1134</span>	  (let (ranges
<span id="L1135" class="ln">  1135</span>	        (max-count 0))
<span id="L1136" class="ln">  1136</span>	    (with-temp-buffer
<span id="L1137" class="ln">  1137</span>	      (insert-file-contents coverage-file)
<span id="L1138" class="ln">  1138</span>	      (go--goto-line 2) ;; Skip over mode
<span id="L1139" class="ln">  1139</span>	      (while (not (eobp))
<span id="L1140" class="ln">  1140</span>	        (let* ((parts (split-string (buffer-substring (point-at-bol) (point-at-eol)) &#34;:&#34;))
<span id="L1141" class="ln">  1141</span>	               (file (car parts))
<span id="L1142" class="ln">  1142</span>	               (rest (split-string (nth 1 parts) &#34;[., ]&#34;)))
<span id="L1143" class="ln">  1143</span>	
<span id="L1144" class="ln">  1144</span>	          (destructuring-bind
<span id="L1145" class="ln">  1145</span>	              (start-line start-column end-line end-column num count)
<span id="L1146" class="ln">  1146</span>	              (mapcar #&#39;string-to-number rest)
<span id="L1147" class="ln">  1147</span>	
<span id="L1148" class="ln">  1148</span>	            (when (string= (file-name-nondirectory file) file-name)
<span id="L1149" class="ln">  1149</span>	              (if (&gt; count max-count)
<span id="L1150" class="ln">  1150</span>	                  (setq max-count count))
<span id="L1151" class="ln">  1151</span>	              (push (make-go--covered :start-line start-line
<span id="L1152" class="ln">  1152</span>	                                      :start-column start-column
<span id="L1153" class="ln">  1153</span>	                                      :end-line end-line
<span id="L1154" class="ln">  1154</span>	                                      :end-column end-column
<span id="L1155" class="ln">  1155</span>	                                      :covered (/= count 0)
<span id="L1156" class="ln">  1156</span>	                                      :count count)
<span id="L1157" class="ln">  1157</span>	                    ranges)))
<span id="L1158" class="ln">  1158</span>	
<span id="L1159" class="ln">  1159</span>	          (forward-line)))
<span id="L1160" class="ln">  1160</span>	
<span id="L1161" class="ln">  1161</span>	      (list ranges (if (&gt; max-count 0) (log max-count) 0)))))
<span id="L1162" class="ln">  1162</span>	
<span id="L1163" class="ln">  1163</span>	(defun go-coverage (&amp;optional coverage-file)
<span id="L1164" class="ln">  1164</span>	  &#34;Open a clone of the current buffer and overlay it with
<span id="L1165" class="ln">  1165</span>	coverage information gathered via go test -coverprofile=COVERAGE-FILE.
<span id="L1166" class="ln">  1166</span>	
<span id="L1167" class="ln">  1167</span>	If COVERAGE-FILE is nil, it will either be inferred from the
<span id="L1168" class="ln">  1168</span>	current buffer if it&#39;s already a coverage buffer, or be prompted
<span id="L1169" class="ln">  1169</span>	for.&#34;
<span id="L1170" class="ln">  1170</span>	  (interactive)
<span id="L1171" class="ln">  1171</span>	  (let* ((cur-buffer (current-buffer))
<span id="L1172" class="ln">  1172</span>	         (origin-buffer (go--coverage-origin-buffer))
<span id="L1173" class="ln">  1173</span>	         (gocov-buffer-name (concat (buffer-name origin-buffer) &#34;&lt;gocov&gt;&#34;))
<span id="L1174" class="ln">  1174</span>	         (coverage-file (or coverage-file (go--coverage-file)))
<span id="L1175" class="ln">  1175</span>	         (ranges-and-divisor (go--coverage-parse-file
<span id="L1176" class="ln">  1176</span>	                              coverage-file
<span id="L1177" class="ln">  1177</span>	                              (file-name-nondirectory (buffer-file-name origin-buffer))))
<span id="L1178" class="ln">  1178</span>	         (cov-mtime (nth 5 (file-attributes coverage-file)))
<span id="L1179" class="ln">  1179</span>	         (cur-mtime (nth 5 (file-attributes (buffer-file-name origin-buffer)))))
<span id="L1180" class="ln">  1180</span>	
<span id="L1181" class="ln">  1181</span>	    (if (&lt; (float-time cov-mtime) (float-time cur-mtime))
<span id="L1182" class="ln">  1182</span>	        (message &#34;Coverage file is older than the source file.&#34;))
<span id="L1183" class="ln">  1183</span>	
<span id="L1184" class="ln">  1184</span>	    (with-current-buffer (or (get-buffer gocov-buffer-name)
<span id="L1185" class="ln">  1185</span>	                             (make-indirect-buffer origin-buffer gocov-buffer-name t))
<span id="L1186" class="ln">  1186</span>	      (set (make-local-variable &#39;go--coverage-current-file-name) coverage-file)
<span id="L1187" class="ln">  1187</span>	
<span id="L1188" class="ln">  1188</span>	      (save-excursion
<span id="L1189" class="ln">  1189</span>	        (go--coverage-clear-overlays)
<span id="L1190" class="ln">  1190</span>	        (dolist (range (car ranges-and-divisor))
<span id="L1191" class="ln">  1191</span>	          (go--coverage-make-overlay range (cadr ranges-and-divisor))))
<span id="L1192" class="ln">  1192</span>	
<span id="L1193" class="ln">  1193</span>	      (if (not (eq cur-buffer (current-buffer)))
<span id="L1194" class="ln">  1194</span>	          (display-buffer (current-buffer) #&#39;display-buffer-reuse-window)))))
<span id="L1195" class="ln">  1195</span>	
<span id="L1196" class="ln">  1196</span>	(provide &#39;go-mode)
</pre><p><a href="/misc/emacs/go-mode.el?m=text">View as plain text</a></p>

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

