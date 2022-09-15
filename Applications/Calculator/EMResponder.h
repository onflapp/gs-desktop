//
//  EMResponder.h
//  EdenMath
//
//  Created by admin on Thu Feb 21 2002.
//  Copyright (c) 2002-2004 Edenwaith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#ifdef GNUSTEP
#define true 1
#endif

typedef enum Op_Type 
{
    NO_OP 	= 0,
    ADD_OP 	= 1,
    SUBTRACT_OP = 2,
    MULTIPLY_OP = 3, 
    DIVIDE_OP 	= 4,       
    EXPONENT_OP = 5,
    XROOT_OP 	= 6,
    MOD_OP 	= 7,
    EE_OP 	= 8,
    NPR_OP 	= 9,
    NCR_OP 	= 10
} OpType;

typedef enum Angle_Type
{
    DEGREE 	= 0,
    RADIAN 	= 1,
    GRADIENT 	= 2
} AngleType;

@interface EMResponder : NSObject 
{
    double current_value;		// the current number (which is being edited)
    double previous_value;		// the other operand (previous operand)
    double e_value;			// the number e
    OpType op_type;		        // the current operator
    AngleType angle_type;	     	// type of angle used (radian, degree, gradient)
    int trailing_digits;		// used in decimal number input
    BOOL isNewDigit;                 	// allow new number in display
}

// class method prototypes

- (double)getCurrentValue;
- (int)getTrailingDigits;
- (void)setCurrentValue:(double)num;
- (void)setState:(NSDictionary *)stateDictionary;
- (NSDictionary *)state;

- (void)newDigit:(int)digit;
- (void)period;
- (void)pi;
- (void) trig_constant: (double) trig_const;
- (void)e;

- (void)clear;
- (void)operation:(OpType)new_op_type;
- (void)enter;

// Algebraic functions
- (void)reverse_sign;
- (void)percentage;

- (void)squared;
- (void)cubed;
- (void) square_root;
- (void) cubed_root;
- (void)ln;
- (void)logarithm;
- (void)factorial;
- (double) factorial: (double) n;

- (void)powerE;
- (void)power10;
- (void)inverse;

// Trigometric functions
- (void)setAngleType:(AngleType)aType;
- (double)deg_to_rad:(double)degrees;
- (double)rad_to_deg:(double)radians;
- (double)grad_to_rad:(double)gradients;
- (double)rad_to_grad:(double)radians;
- (void)sine;
- (void)cosine;
- (void)tangent;
- (void)arcsine;
- (void)arccosine;
- (void)arctangent;

// Probability functions
- (double) generate_random_num;
- (void)random_num;


@end
