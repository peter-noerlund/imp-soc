module BB
    (
        input I,
        input T,
        output O,
        inout B
    );

    assign O = I;

    wire _unused = &{T, B};    
endmodule
