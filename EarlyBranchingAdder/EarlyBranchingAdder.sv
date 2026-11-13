`timescale 1ns/1ps

module EarlyBranchingAdder (
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] res
);

    wire [31:0] p;
    wire [31:0] g;
    wire [6:1] group_p;
    wire [6:0] group_g;
    genvar k;

    wire carry0_1, carry1_2, carry2_3, carry3_4;
    wire carry4_5, carry5_6, carry6_7;

    assign p = a ^ b;
    assign g = a & b;

    // computing Pgroups and Ggroups for carries between blocks
    generate
        for(k=0; k<7; k=k+1) begin : groups
            if (k>0) begin : gen_p
                assign group_p[k] =
                    p[4*k+3] & p[4*k+2] & p[4*k+1] & p[4*k];
            end

            assign group_g[k] =
                g[4*k+3]
                | (p[4*k+3] & g[4*k+2])
                | (p[4*k+3] & p[4*k+2] & g[4*k+1])
                | (p[4*k+3] & p[4*k+2] & p[4*k+1] & g[4*k]);
        end
    endgenerate

    // computing carries (carry4, carry8, ..., carry28)
    assign carry0_1 = group_g[0];

    assign carry1_2 =
        group_g[1]
        | (group_p[1] & group_g[0]);

    assign carry2_3 =
        group_g[2]
        | (group_p[2] & group_g[1])
        | (group_p[2] & group_p[1] & group_g[0]);

    assign carry3_4 =
        group_g[3]
        | (group_p[3] & group_g[2])
        | (group_p[3] & group_p[2] & group_g[1])
        | (group_p[3] & group_p[2] & group_p[1] & group_g[0]);


    assign carry4_5 =
        group_g[4]
        | (group_p[4] & group_g[3])
        | (group_p[4] & group_p[3] & group_g[2])
        | (group_p[4] & group_p[3] & group_p[2] & group_g[1])
        | (group_p[4] & group_p[3] & group_p[2] & group_p[1]
        & group_g[0]);

    assign carry5_6 =
        group_g[5]
        | (group_p[5] & group_g[4])
        | (group_p[5] & group_p[4] & group_g[3])
        | (group_p[5] & group_p[4] & group_p[3] & group_g[2])
        | (group_p[5] & group_p[4] & group_p[3] & group_p[2]
        & group_g[1])
        | (group_p[5] & group_p[4] & group_p[3] & group_p[2]
        & group_p[1] & group_g[0]);

    assign carry6_7 =
        group_g[6]
        | (group_p[6] & group_g[5])
        | (group_p[6] & group_p[5] & group_g[4])
        | (group_p[6] & group_p[5] & group_p[4] & group_g[3])
        | (group_p[6] & group_p[5] & group_p[4] & group_p[3]
        & group_g[2])
        | (group_p[6] & group_p[5] & group_p[4] & group_p[3]
        & group_p[2] & group_g[1])
        | (group_p[6] & group_p[5] & group_p[4] & group_p[3]
        & group_p[2] & group_p[1] & group_g[0]);

    CLA4bit block0 (
        .p(p[3:0]),
        .g(g[2:0]),
        .carry_in(1'b0),
        .res(res[3:0])
    );

    CLA4bit block1 (
        .p(p[7:4]),
        .g(g[6:4]),
        .carry_in(carry0_1),
        .res(res[7:4])
    );

    CLA4bit block2 (
        .p(p[11:8]),
        .g(g[10:8]),
        .carry_in(carry1_2),
        .res(res[11:8])
    );

    CLA4bit block3 (
        .p(p[15:12]),
        .g(g[14:12]),
        .carry_in(carry2_3),
        .res(res[15:12])
    );

    CLA4bit block4 (
        .p(p[19:16]),
        .g(g[18:16]),
        .carry_in(carry3_4),
        .res(res[19:16])
    );

    CLA4bit block5 (
        .p(p[23:20]),
        .g(g[22:20]),
        .carry_in(carry4_5),
        .res(res[23:20])
    );

    CLA4bit block6 (
        .p(p[27:24]),
        .g(g[26:24]),
        .carry_in(carry5_6),
        .res(res[27:24])
    );

    CLA4bit block7 (
        .p(p[31:28]),
        .g(g[30:28]),
        .carry_in(carry6_7),
        .res(res[31:28])
    );

endmodule
