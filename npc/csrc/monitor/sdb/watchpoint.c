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

#include <sdb.h>
#include <isa.h>
#ifdef CONFIG_WP

#define NR_WP 32

typedef struct watchpoint {
  int NO;
  //struct watchpoint *pre;
  struct watchpoint *next;
  bool usage;
  int oldv;
  int newv;
  char expr[30];

  /* TODO: Add more members if necessary */

} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].usage = false;
    //wp_pool[i].pre = (i == 0 ? NULL : &wp_pool[i - 1]);  
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

WP* new_wp(){
    if(free_ != NULL){
    if(head == NULL){
    head = free_;
    }
    WP* newd = free_;
    free_ -> usage =true;
    free_ = free_->next;
    return newd;
    }

    printf("no empty wp!\n");
    assert(0);
}

void free_wp(WP *wp){
  if(wp ->NO == head ->NO){
    if(head ->next == free_){
      init_wp_pool();
      //head = NULL;
      printf("all wp deleted\n");
    }
    else {
       head -> usage =false;
       head = head ->next;
       printf("delete success\n");
    }
    return ;
  }
  else if(wp -> next == free_){
    free_ = wp;
    wp -> usage = false;
    return ;
    printf("delete success\n");
  }
  else{
    for(WP* tmp = head ;tmp != free_; tmp=tmp ->next){
      if(tmp ->next == wp)
      {   
          wp ->usage = false;
          tmp ->next =wp ->next;
          printf("delete success\n");
          return ;
      }
    }
  }
    printf("error wp.no\n");
    return ;
}

void wp_display() {
  bool empty = false;
  for(int i = 0; i < NR_WP; i++){
    if(wp_pool[i].usage == true){
      if(!empty){
          printf("NUM \told value \tnew value\n");
      }
      empty = true;
      printf("%d:\t%u\t\t%u\n",wp_pool[i].NO,wp_pool[i].oldv,wp_pool[i].newv);
    }
  }
  if(!empty) printf("NO WP ON USE!\n");
  return ;
}

void wp_create(char *args,word_t res){
    WP* newwp;
    newwp =new_wp();
    strcpy(newwp -> expr, args);
    newwp -> oldv = res;
    newwp -> newv = res;
    printf("creat wp success\n");
}

bool wp_check(){
  bool check =false;
   for(int i = 0; i < NR_WP; i++){
    if(wp_pool[i].usage == true){
      bool success = true;
      word_t cmp=expr(wp_pool[i].expr,&success);
      if(success){
        if(cmp != wp_pool[i].newv){
          check = true;
          wp_pool[i].oldv = wp_pool[i].newv;
          wp_pool[i].newv = cmp;
          printf("%d change oldv:%u\tnewv:%u\n",wp_pool[i].NO,wp_pool[i].oldv,wp_pool[i].newv);
        }
      }
      else printf("error expr!\n");
    }
   }
   return check;
}

void wp_delete(int num){
    for(WP* tmp = head;tmp != free_; tmp=tmp ->next){
        if(tmp -> NO == num) {
          free_wp(tmp);
          //free_wp(head-100);
          wp_display();
          return ;
        }
    }
    printf("num error!\n");
    return ;
}
/* TODO: Implement the functionality of watchpoint */

#endif