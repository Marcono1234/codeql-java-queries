class Test {
    /**
     * {@code this is not <b>bold</b> text}
     * {@literal not <i>italic</i> text}
     * {@code not a <h1>header</h1>}
     * {@code test <br/> test}
     * {@code test <br /> test}
     * {@code test <CODE>text</CODE>}
     * {@code test <Code>text</Code>}
     */
    int bad1;

    /**
     * {@code test &#x0;}
     * {@code test &#x1;}
     * {@code test &#xf;}
     * {@code test &#xFFFF;}
     * {@code test &#x12AB;}
     * {@code test &#x10FFFF;} // max code point
     * 
     * {@code test &#0;}
     * {@code test &#1114111;} // max code point
     * 
     * {@code test &aacute;}
     * {@code test &Aacute;}
     */
    int bad2;

    /**
     * regular text <b>test</b>
     * with character references &#x0; and &#1114111; and &aacute;
     */
    int good1;

    /**
     * {@code a & b}
     * {@code a < b && b > c}
     */
    int good2;

    /**
     * Directly contains HTML code, so most likely intended
     * {@code <br/>}
     * {@code &#x1;}
     * {@code "&#x1;"}
     * {@code '&#x1;'}
     */
    int good3;

    /**
     * {@link List a <b>List</b>}
     */
    int good4;
}
