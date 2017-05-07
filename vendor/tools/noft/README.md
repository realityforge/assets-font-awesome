# noft

[![Build Status](https://secure.travis-ci.org/realityforge/noft.png?branch=master)](http://travis-ci.org/realityforge/noft)

`noft` is a tool to extract svg icons from icon fonts and generate helpers to render the icons
in different web frameworks.

## Motivation

Several of our applications made use of font icon libraries either as part of larger frontend frameworks
(i.e. [Bootstrap](http://getbootstrap.com/)) or using individual libraries (i.e. [Font Awesome](http://fontawesome.io/)).
Often our applications would use an extremely small subset of the icons from these sources. The application
would also combine it with custom icon fonts constructed on websites such as [FlatIcon](flaticon.com). As a
result our applications would have 100s or 1000s of unused css classes and unused glyphs. For frameworks
like [GWT](http://www.gwtproject.org/) this also necessitated 1000s of lines of unused java code for
`CssResource` bundles. All of this slowed down development time and increased the size of assets downloaded
by web clients. In some cases we were forced to manually remove unused css classes, font glyphs and java methods
but it was labour intensive (and thus expensive), somewhat error prone and extremely boring. 

Looking towards the architecture of future applications we came across several articles about moving from
icon fonts to svg. In particular the article["Making the Switch Away from Icon Fonts to SVG: Converting Font Icons to SVG"](https://sarasoueidan.com/blog/icon-fonts-to-svg/) by Sara
Soueidan and the article ["Delivering Octicons with SVG"](https://github.com/blog/2112-delivering-octicons-with-svg)
from GitHub about their move away from font icons motivated us to make the switch. Unwilling to lose the investment
in our current icons we created this tool to help automate the conversion of our current icons to helpers that
injected icons where we needed it.
