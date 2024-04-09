  /***************************************************************************************
  * Copyright (c) 2014-2022 Zihao Yu, Nanjing University
  *
  * NEMU is licensed under Mulan PSL v2.
  * You can use this software according to the terms and conditions of the Mulan PSL v2.
  * You may obtain a copy of Mulan PSL v2 at:
  *          http://license.coscl.org.cn/MulanPSL2
  *
  * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
  * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
  * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
  *
  * See the Mulan PSL v2 for more details.
  ***************************************************************************************/

  #include <isa.h>
  #include <memory/paddr.h>

  /* We use the POSIX regex functions to process regular expressions.
  * Type 'man regex' for more information about POSIX regex functions.
  */
  #include <regex.h>

  word_t eval(int p, int q, bool *success);

  enum {
    TK_NOTYPE = 256,
    TK_HEX,     //HEX
    TK_NEGNUM,  //negative number
    TK_NUMBER,  // integer
    TK_POINTER, //pointer
    TK_REGISTER, //register
    TK_PLUS,    // +
    TK_MINUS,   // -
    //TK_PC,      //pc
    TK_MULTIPLY, // *264
    TK_DIVIDE,  // /
    TK_LPAREN,  // (
    TK_RPAREN,  // ) 
    TK_EQ,
    TK_NEQ,
    TK_AND,
    /* TODO: Add more token types */

  };

  static struct rule {
    const char *regex;
    int token_type;
  } rules[] = {

    /* TODO: Add more rules.
    * Pay attention to the precedence level of different rules.
    */

    {" +", TK_NOTYPE},    // spaces
    {"\\+", TK_PLUS},         // plus
   // {"\\$pc", TK_PC},   // *
    {"0x[0-9,a-f]+",TK_HEX},  //hex
    {"\\$+[a-zA-Z0-9]+", TK_REGISTER},
    {"-[0-9]+", TK_NEGNUM},  // 支持带负号前缀的整数
    {"[0-9]+", TK_NUMBER},  //  zhengshu
   // {"\\*\\$[a-zA-Z0-9]+", TK_POINTER}, //zhizhen
    {"-", TK_MINUS},        // -
    {"\\*", TK_MULTIPLY},   // *
    {"/", TK_DIVIDE},       // /
    {"\\(", TK_LPAREN},     // (
    {"\\)", TK_RPAREN},     // )
    {"==", TK_EQ},        // equal
    {"!=", TK_NEQ},        // not equal
    {"==", TK_EQ},        // equal
    {"&&", TK_AND},        // equal

  };

  #define NR_REGEX ARRLEN(rules)

  static regex_t re[NR_REGEX] = {};

  /* Rules are used for many times.
  * Therefore we compile them only once before any usage.
  */
  void init_regex() {
    int i;
    char error_msg[128];
    int ret;

    for (i = 0; i < NR_REGEX; i ++) {
      ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
      if (ret != 0) {
        regerror(ret, &re[i], error_msg, 128);
        panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
      }
    }
  }

  typedef struct token {
    int type;
    char str[32];
  } Token;

  // static Token tokens[32] __attribute__((used)) = {};
  static Token tokens[128] __attribute__((used)) = {};
  static int nr_token __attribute__((used))  = 0;

  static bool make_token(char *e) {
    int position = 0;
    int i;
    regmatch_t pmatch;

    nr_token = 0;

    while (e[position] != '\0') {
      /* Try all rules one by one. */
      for (i = 0; i < NR_REGEX; i ++) {
        if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
          char *substr_start = e + position;
          int substr_len = pmatch.rm_eo;

          // Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
          //     i, rules[i].regex, position, substr_len, substr_len, substr_start);

          position += substr_len;

          /* TODO: Now a new token is recognized with rules[i]. Add codes
          * to record the token in the array `tokens'. For certain types
          * of tokens, some extra actions should be performed.
          */
          
          if (substr_len > 32) { // in case str overflow
            printf("expr too Long!\n");
            assert(0);
          }

          switch (rules[i].token_type) {
              case TK_HEX:
              case TK_NUMBER:
              case TK_PLUS:
              case TK_MINUS:
              //case TK_MULTIPLY:
              case TK_REGISTER:
              case TK_DIVIDE:
              case TK_LPAREN:
              case TK_RPAREN:
              case TK_EQ:
              case TK_AND:
              case TK_NEQ:
                strncpy(tokens[nr_token].str, substr_start, substr_len);
                tokens[nr_token].str[substr_len] = '\0';
                tokens[nr_token].type = rules[i].token_type;
                nr_token++;
                break;
              case TK_NEGNUM:
                if(nr_token !=0 && (tokens[nr_token-1].type == TK_RPAREN ||
                   tokens[nr_token-1].type== TK_NUMBER || 
                   tokens[nr_token-1].type == TK_NEGNUM ||
                   tokens[nr_token-1].type == TK_REGISTER ||
                   tokens[nr_token-1].type == TK_HEX )){
                  //position -= substr_len;
                  int substr_len_tmp = substr_len;
                  substr_len =1;
                  strncpy(tokens[nr_token].str, substr_start, substr_len);
                  tokens[nr_token].str[substr_len] = '\0';
                  tokens[nr_token].type = TK_MINUS;
                  nr_token++;
                  //position +=substr_len_tmp;
                  strncpy(tokens[nr_token].str, substr_start+1, substr_len_tmp-1);
                  tokens[nr_token].str[substr_len_tmp-1] = '\0';
                  tokens[nr_token].type = TK_NUMBER;
                  nr_token++;
                  break;
                }
              else {
                strncpy(tokens[nr_token].str, substr_start, substr_len);
                tokens[nr_token].str[substr_len] = '\0';
                tokens[nr_token].type = rules[i].token_type;
                nr_token++;
                break;
                }
              case TK_MULTIPLY:
                  if(nr_token !=0 && (tokens[nr_token-1].type == TK_RPAREN || 
                    tokens[nr_token-1].type== TK_NUMBER || 
                    tokens[nr_token-1].type == TK_NEGNUM ||
                    tokens[nr_token-1].type == TK_HEX ||
                    tokens[nr_token-1].type == TK_REGISTER )){
                 // position -= substr_len;
                strncpy(tokens[nr_token].str, substr_start, substr_len);
                tokens[nr_token].str[substr_len] = '\0';
                  tokens[nr_token].type = TK_MULTIPLY;
                  nr_token++;
                 // position +=substr_len_tmp;
                  break;
                }
              else {
                strncpy(tokens[nr_token].str, substr_start, substr_len);
                tokens[nr_token].str[substr_len] = '\0';
                tokens[nr_token].type = TK_POINTER;
                nr_token++;
                break;
                }
            
              case TK_NOTYPE: break;
              default: assert(0);
          }

          break;
        }
      }

      if (i == NR_REGEX) {
        printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
        return false;
      }
    }

    return true;
  }


  bool check_parentheses(int l, int r) {
    int i, flag = 0;
    if (tokens[l].type !=  TK_LPAREN || tokens[r].type != TK_RPAREN)
      return false;
    for (i = l; i <= r; i++) {
      if (tokens[i].type == TK_LPAREN)
        flag++;
      else if (tokens[i].type == TK_RPAREN)
        flag--;
      if (flag == 0 && i < r)
        return false;
      else if(flag < 0 && i < r){
          printf("error expr format!\n");
          return false;
      }
    }
    if (flag != 0)
      return false;
    return true;
  }


  int dominant_operator(int l, int r) {
    int i, pos = l;
    int flag = 0;
    int prior = 100;
    for (i = l; i <= r; i++) {
      if (tokens[i].type == TK_NUMBER || tokens[i].type == TK_HEX || tokens[i].type == TK_NEGNUM || tokens[i].type == TK_REGISTER)
        continue;
      if (tokens[i].type == TK_LPAREN ) {
        flag ++;
        i ++;
        while (i <= r) {
          if (tokens[i].type == TK_LPAREN)
            flag ++;
          else if (tokens[i].type == TK_RPAREN)
            flag--;
          if (flag == 0)
            break;
          i ++;
        }
      }
      if (tokens[i].type == TK_PLUS || tokens[i].type == TK_MINUS) {
        pos = i;
        prior = 0;
      }
      else if(tokens[i].type == TK_MULTIPLY || tokens[i].type == TK_DIVIDE){
          if(prior >= 1){
            pos = i;
            prior =1;
          }
      }
      else if(tokens[i].type == TK_EQ || tokens[i].type == TK_NEQ || tokens[i].type == TK_AND){
          if(prior >=2 ){
            pos = i;
            prior =2;
          }
      }
      else if(tokens[i].type == TK_POINTER){
          if(prior >=3 ){
            pos = i;
            prior =3;

          }
      }
    }
    return pos;
  }

word_t eval(int p, int q, bool *success) {
    if (p > q) {
      *success = false;
      return 0;
    }
    else if (p == q) {
      /* Single token.
      * For now this token should be a number.
      * Return the value of the number.
      */
      word_t num=0;
      if(tokens[p].type ==TK_NUMBER ){
          sscanf(tokens[p].str,"%u",&num);
      }
      else if(tokens[p].type == TK_NEGNUM){
          sscanf(tokens[p].str,"%d",&num);
      }
      else if(tokens[p].type ==TK_HEX){
      sscanf(tokens[p].str,"%x",&num);
      }
      else if(tokens[p].type ==TK_REGISTER){
        if(strncmp(tokens[p].str+1, "pc", 2) == 0){
          num = cpu.pc; 
        }
        else{
          num = isa_reg_str2val(tokens[p].str+1 , success);
        }
      }
      return num;
    }
    else if (check_parentheses(p, q) == true) {
      /* The expression is surrounded by a matched pair of parentheses.
      * If that is the case, just throw away the parentheses.
      */
      return eval(p + 1, q - 1, success);
    }
    else {
      /* We should do more things here. */
      word_t val1,val2;

      int op = dominant_operator(p, q);
      if (op < 0) {
      *success = false;
      return -1;
      }
      else if(op == 0){
      val1 = 0;
      val2 = eval(op + 1, q, success);
      }
      else {
      val1 = eval(p, op - 1, success);
      val2 = eval(op + 1, q, success);

      }
      switch (tokens[op].type) {
        case TK_PLUS: return val1 + val2;
        case TK_MINUS: return val1 - val2;
        case TK_MULTIPLY: return val1 * val2;
        case TK_DIVIDE:
          if (val2 == 0) {
            *success = false;
            return -1; 
          }
          return val1 / val2;
        case TK_AND: return val1 && val2;
        case TK_EQ: return val1 == val2;
        case TK_NEQ:  return val1 != val2;
        case TK_POINTER: 
          if(val2==0){
             *success = false;
            return -1; 
          }
          word_t result;
          result = paddr_read(val2,4);
          return result;
        default: assert(0);
        }
      }
  }


  word_t expr(char *e, bool *success) {
    if (!make_token(e)) {
      *success = false;
      return 0;
    }

    /* TODO: Insert codes to evaluate the expression. */
    return eval(0, nr_token - 1, success);

  }
