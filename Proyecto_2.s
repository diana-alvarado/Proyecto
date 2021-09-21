; Archivo: labs.S
; Dispositivo: PIC16F887
; Autor: Diana Alvarado
; Compilador: pic-as (v2.30), MPLABX V5.40
; Programa: Reloj
; Hardware: Cinco botones y un display
; Creado: 13 septiembre, 2021
; Última modificación: 12 sept, 2021
; PIC16F887 Configuration Bit Setting
; Assembly source line config statements
PROCESSOR 16F887
 #include <xc.inc>
 
 ;configuration word 1
  CONFIG FOSC=INTRC_NOCLKOUT	// Oscillador Interno sin salidas, XT
  CONFIG WDTE=OFF   // WDT disabled (reinicio repetitivo del pic)
  CONFIG PWRTE=OFF   // PWRT enabled  (espera de 72ms al iniciar)
  CONFIG MCLRE=OFF  // El pin de MCLR se utiliza como I/O
  CONFIG CP=OFF	    // Sin protección de código
  CONFIG CPD=OFF    // Sin protección de datos
  CONFIG BOREN=OFF  // Sin reinicio cuándo el voltaje de alimentación baja de 4V
  CONFIG IESO=OFF   // Reinicio sin cambio de reloj de interno a externo
  CONFIG FCMEN=OFF  // Cambio de reloj externo a interno en caso de fallo
  CONFIG LVP=OFF     // programación en bajo voltaje
 
 ;configuration word 2
  CONFIG WRT=OFF    // Protección de autoescritura por el programa desactivada
  CONFIG BOR4V=BOR40V // Reinicio abajo de 4V, (BOR21V=2.1V)
  
 ;-------------------------------- | macros | ---------------------------------; 
  reinicio_timer0 macro   ;ciclo de 2 mseg segundo
    banksel   PORTA   
    movlw   255      
    movwf   TMR0    
    bcf	    T0IF    
    endm
    
 reinicio_timer1 macro   ;ciclo de 1  segundo
    movlw   194	    ;cargando valores iniciales del conteo   255
    movwf   TMR1H	    
    movlw   247						    ;225
    movwf   TMR1L
    bcf	    TMR1IF 
    endm
    
wdivl	macro divisor  
						    
	movwf	var2+0   
	clrf	var2+1 
	
	incf	var2+1   ;ver cuantas veces se a restado
	
	movlw	divisor  
	subwf	var2, f	
	btfsc   CARRY    

	goto	$-4   
	
	
	movlw	divisor	    
	addwf	var2, W	    
	movwf	residuo	    ;
	
	decf	var2+1,W   
	movwf	cociente   
	
	endm
;-------------------------------- | variables | -------------------------------;
PSECT	udata_bank0
  bandera_t0:	DS 1
  display_var:	DS 4
  cociente:	DS 1
  residuo:	DS 1
  var2:		DS 2
  unidad:	DS 1
  decena:	DS 1
  centena:	DS 1

    
  bandera_int: DS 1
  estado:	DS 1
  contador_t1: DS 2   
    
  display_hora:	DS 1
  display_min:	DS 1
  display_dia:	DS 1
  display_mes:	DS 1    
  unidad2:	DS 1
  decena2:	DS 1
    
  pruebas:	DS 4
    
  MODO		EQU 4
  UP1		EQU 0
  DOWN1		EQU 1
  UP2		EQU 2
  DOWN2		EQU 3	
PSECT	udata_shr
W_TEMP:	     DS 1
STATUS_TEMP: DS 1

;----------------------------- | vector reset | -------------------------------;
PSECT resVect, class=CODE, abs, delta=2   
ORG 00h         
    
resetVec:       
  PAGESEL main	
  goto main      
  ;------------------------- | vector interrupcion | ----------------------------;
PSECT intVect, class=CODE, abs, delta=2    ;SECTOR DEL VECTOR de interrupciones
ORG 04h          ;posicion 0004h para las interrupciones

push:
    movwf   W_TEMP	
    swapf   STATUS, W  
    movwf   STATUS_TEMP 
    
isr:
    btfsc   T0IF 
    call    int_t0	  
    
    btfsc   TMR1IF
    call    int_t1	 
    
    btfsc   TMR2IF
    call    int_t2	  
    
    btfsc   RBIF	 
    call    int_iocb
      
pop:
    swapf   STATUS_TEMP, W  
    movwf   STATUS	    
    swapf   W_TEMP, F	   
    swapf   W_TEMP, W	  
    retfie    
    
;--------------------- | SUB RUTINAS INTERRUPCION| ----------------------------;
int_iocb:		     ;interrupcion de PORTB para cambio de estado
    banksel PORTB
    btfss   PORTB, MODO         ;con el pin 6 del PORTB se inc    
    incf    estado
    
    movlw   1
    subwf   estado, 0
    btfsc   ZERO
    goto    S1 ;hora
   
    movlw   2 
    subwf   estado, 0
    btfsc   ZERO
    goto    S2 ;fecha
    
    movlw   3
    subwf   estado, 0
    btfsc   ZERO ;confug hora
    goto    S3
    
    movlw   4
    subwf   estado, 0
    btfsc   ZERO
    goto    S4 ;configuracion Fecha
    
    movlw   5
    subwf   estado, 0
    btfsc   ZERO
    clrf    estado
    goto    reiniciar
    
S1:
    bcf	    RBIF
    return
    
S2:
    bcf	    RBIF
    return
    
S3:
    btfss   PORTB, UP1
    incf    display_hora
    btfss   PORTB, DOWN1
    decf    display_hora

    
    btfss   PORTB, UP2
    incf    display_min
    btfss   PORTB, DOWN2
    decf    display_min
    
    bcf	    RBIF
    return
    
S4:

    btfss   PORTB, UP1
    incf    display_dia
    btfss   PORTB, DOWN1
    decf    display_dia

    btfss   PORTB, UP2
    incf    display_mes
    btfss   PORTB, DOWN2
    decf   display_mes
    bcf	    RBIF
    return

reiniciar:
    clrf    estado
    incf    estado
    bcf	    RBIF
    return
    
int_t0:	      ;interrupcion del TMRO
    reinicio_timer0   ;10 mseg
    clrf    PORTD     ;apagar displays para no mostrar traslapes
      
    btfss   bandera_t0, 0  ;ver si el bit 0 de banderas es 1 para saltarse a la prox
    goto    display_0
    
    btfss   bandera_t0, 1 
    goto   display_1
  
    btfss   bandera_t0, 2 
    goto   display_2
    
    btfss   bandera_t0, 3 
    goto   display_3
       
display_0:
    bcf     bandera_t0, 3
    bsf	    bandera_t0, 0
    movf    display_var, W 
    movwf   PORTC	    
    bsf	    PORTD, 2
    bcf     PORTD, 5
    return
    
display_1:
    bcf	    bandera_t0, 0
    bsf	    bandera_t0, 1
    movf    display_var+1, W 
    movwf   PORTC	    
    bsf	    PORTD, 3	
    bcf PORTD, 2
    return
    
display_2:
    bcf	    bandera_t0, 1
    bsf	    bandera_t0, 2	    
    movf    display_var+2, W 
    movwf   PORTC	    
    bsf	    PORTD, 4	    
    bcf PORTD, 3
    return

display_3:
    bcf	    bandera_t0, 2
    bsf	    bandera_t0, 3	    
    movf    display_var+3, W 
    movwf   PORTC	    
    bsf	    PORTD, 5	    
    bcf     PORTD, 4
    return

int_t1:
    reinicio_timer1	    
    incf    contador_t1      ;incrementar variable cada seg
    return 
    
int_t2:
    bcf	    TMR2IF	    ;limpiar bandera TMR2
    clrf    PORTA	    ;limpiar puerto A
    
    btfss   bandera_int, 0  ;ver si el bit 0 de bandera_inter es 1 para saltarse a la prox
    goto    inter      ;si no se llama a intermitente
    goto    reinicio_inter    ;si si reiniciar interrupcion
    
inter:
    bsf	    bandera_int, 0  
    bsf	    PORTA, 5	      
    bsf	    PORTA, 4	     
    return
    
reinicio_inter:
    bcf	    bandera_int, 0  
    bcf	    PORTA, 5
    bcf	    PORTA, 4
    clrf    bandera_int     
    return
    
PSECT code, delta=2, abs 
ORG 100h
 
;-------------------------------- | TABLA | ----------------------------------;

tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0 ;PCLATH = 01
    andlw   00001111B         ;va a poner en 0 todo lo superior a 16, el valor mas grande es f
    addwf   PCL		      ;PC = PCLATH + PCL 
    retlw   00111111B	      ;return y devuelve una literal
    retlw   00000110B	     
    retlw   01011011B
    retlw   01001111B	      ;3
    retlw   01100110B	      ;4
    retlw   01101101B	      ;5
    retlw   01111101B	      ;6
    retlw   00000111B	      ;7
    retlw   01111111B	      ;8
    retlw   01101111B	      ;9
    
    retlw   01110111B	      ;A
    retlw   01111100B	      ;B
    retlw   00111001B	      ;C
    retlw   01011110B	      ;D
    retlw   01111001B	      ;E
    retlw   01110001B	      ;F
   
;--------------------------- | CONFIGURACIÓN | --------------------------------;
main:
    call config_io
    call config_reloj
    call config_iocrb
    call config_timer0
    call config_tmr1	    ;config tmr1
    call config_tmr2	    ;config tmr2
    call config_interrupcion
    banksel PORTA
    
;--------------------------- | LOOP PRINCIPAL | -------------------------------; 
loop: ;para que no se reinice constantemente
    call    modo_de_estados
    goto    loop

;---------------------------- | SUB RUTINAS | ---------------------------------; 
modo_de_estados:

    movlw   1
    subwf   estado, 0
    btfsc   ZERO
    goto    estado_hora
   
    movlw   2
    subwf   estado, 0
    btfsc   ZERO
    goto    estado_fecha
    
    movlw   3
    subwf   estado, 0
    btfsc   ZERO
    goto    config_hora
    
    movlw   4
    subwf   estado, 0
    btfsc   ZERO
    goto    config_fecha
     
    movlw   5
    subwf   estado, 0
    btfsc   ZERO
    clrf    estado
    goto    reiniciar1    
    
estado_hora:
    bsf	    PORTA, 0

    call    conver_min
    call    preparar_min
    call    conver_hora
    call    preparar_hora
    call    incremento_horas
    call    incremento_minutos

    goto    modo_de_estados
    
estado_fecha:
    clrf    PORTD
    bcf	    PORTA, 0
    bsf	    PORTA, 1
    call valor_inicial_mes
    call valor_inicial_dia
    call    incremento_meses
    call    incremento_dias
    call    conversion_mes
    call    preparar_mes
    
    call    conversion_dia_31
    call    preparar_dia

    goto    modo_de_estados
    
config_hora:
    clrf    PORTD
    bcf	    PORTA, 1
    bsf	    PORTA, 2
    
    call    conver_min
    call    preparar_min
    call    conver_hora
    call    preparar_hora
    goto    modo_de_estados
    
config_fecha:
    bcf	    PORTA, 2
    bsf	    PORTA, 3
    
    call    conversion_mes
    call    preparar_mes
    call    hola
    goto    modo_de_estados
    
reiniciar1:
    clrf    PORTA
    goto     modo_de_estados

;------------| SUB RUTINAS PARA CONFIG HORA|---------------------;
conver_min:
    movf    display_min, W ;
    
    wdivl   196		    
    movf    cociente, W
    movwf   decena	    
    movf    residuo, W
    movwf   unidad
    
    wdivl   60		    
    movf    cociente, W
    movwf   decena	   
    movf    residuo, W
    movwf   unidad
   
    wdivl   10		     
    movf    cociente, W
    movwf   decena	     
    movf    residuo, W
    movwf   unidad
    return
    
preparar_min:
    movf    unidad, W	    ;
    call    tabla	    
    movwf   display_var+3   
    
    movf    decena, W	   
    call    tabla
    movwf   display_var+2  
    return

conver_hora:
    movf    display_hora, W 
    
    wdivl   232		    
    movf    cociente, W
    movwf   decena2	    
    movf    residuo, W
    movwf   unidad2

    wdivl   24		   
    movf    cociente, W
    movwf   decena2	    
    movf    residuo, W
    movwf   unidad2
   
    wdivl   10		    
    movf    cociente, W
    movwf   decena2	     
    movf    residuo, W
    movwf   unidad2
    return
    
preparar_hora:
    movf    unidad2, W	    
    call    tabla	    
    movwf   display_var+1   
    
    movf    decena2, W	    
    call    tabla
    movwf   display_var+0  
    return

incremento_minutos:
    movf    contador_t1, W  
    sublw   60	      

    btfss   ZERO        
    return
    clrf    contador_t1       
    incf    display_dia	
    return
    
incremento_horas:
    movf    display_min, W   
    sublw   60	      

    btfss   ZERO        
    return
    clrf    display_min        
    incf    display_hora	
    return

;------------| SUB RUTINAS PARA MOSTRAR FECHA|-------------------;

valor_inicial_mes:
    movlw   0
    subwf   display_mes, 0
    btfsc   ZERO
    incf    display_mes
    return
    
valor_inicial_dia:
    movlw   0
    subwf   display_dia, 0
    btfsc   ZERO
    incf    display_dia
    return
    
incremento_dias:
    movf    display_hora, W    
    sublw   24		    

    btfss   ZERO	    
    return
    clrf    display_hora	    
    incf    display_dia    

incremento_meses:  
    movlw   1
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mes1
    
    movlw   2
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mes2
    
    movlw   3
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mes3
    
    movlw   4
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mes4
    
    movlw   5
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mes5
    
    movlw   6
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mes6
    
    movlw   7
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mes7
    
    movlw   8
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mes8
    
    movlw   9
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mes9
    
    movlw   10
    subwf  display_mes, 0
    btfsc   ZERO
    goto    mes10
    
    movlw   11
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mes11
    
    movlw   12
    subwf  display_mes, 0
    btfsc   ZERO
    goto    mes12
    
mes1:
    movf    display_dia, W   ;moverla al acumulador
    sublw   32		  ;restar literal 32 a W 
    btfss   ZERO	 
    return
    clrf    display_dia      ;limpiar dias
    incf    display_mes	  ;incrementar mes
    return  

mes2:
    movf    display_dia, W   
    sublw   29		  
    btfss   ZERO	  
    return
    clrf    display_dia      
    incf    display_mes	  ;
    return  

mes3:
    movf    display_dia  , W   
    sublw   32		  
    btfss   ZERO	  
    return
    clrf    display_dia        
    incf    display_mes	  
    return  

mes4:
    movf    display_dia  , W   
    sublw   31		 
    btfss   ZERO	  
    return
    clrf    display_dia       
    incf    display_mes	  
    return 
    
mes5:
    movf    display_dia, W   ;
    sublw   32		  
    btfss   ZERO	  
    return
    clrf    display_dia      
    incf    display_mes	 
    return  

mes6:
    movf    display_dia, W  
    sublw   31		  
    btfss   ZERO	  
    return
    clrf    display_dia     
    incf    display_mes	  
    return

mes7:
    movf    display_dia, W   
    sublw   32		 
    btfss   ZERO	 
    return
    clrf    display_dia    
    incf    display_mes	 
    return  
    
mes8:
    movf    display_dia, W   
    sublw   32		  
    btfss   ZERO	 
    return
    clrf    display_dia     
    incf    display_mes	
    return  
    
mes9:
    movf    display_dia, W   
    sublw   31		  
    btfss   ZERO	  
    return
    clrf    display_dia     
    incf    display_mes	 
    return
    
mes10:
    movf    display_dia, W  
    sublw   32		  
    btfss   ZERO	  
    return
    clrf    display_dia     
    incf    display_mes	  
    return  
    
mes11:
    movf    display_dia, W  
    sublw   31		  
    btfss   ZERO	 
    return
    clrf    display_dia    
    incf    display_mes	  
    return

mes12:
    movf    display_dia, W   
    sublw   32		  
    btfss   ZERO	  
    return
    clrf    display_dia    
    clrf    display_mes	  
    return  
    
;------------| SUB RUTINAS PARA EL ESTADO 4 (CONFIG FECHA)|-------------------;
hola: 
    movlw   1
    subwf   display_mes, 0
    btfsc   ZERO
    goto    enero
   
    movlw   2
    subwf   display_mes, 0
    btfsc   ZERO
    goto    febrero
    
    movlw   3
    subwf   display_mes, 0
    btfsc   ZERO
    goto    marzo

    movlw   4
    subwf   display_mes, 0
    btfsc   ZERO
    goto    abril
    
    movlw   5
    subwf   display_mes, 0
    btfsc   ZERO
    goto    mayo
    
    movlw   6
    subwf   display_mes, 0
    btfsc   ZERO
    goto    junio
    
    movlw   7
    subwf   display_mes, 0
    btfsc   ZERO
    goto    julio
    
    movlw   8
    subwf   display_mes, 0
    btfsc   ZERO
    goto    agosto
    
    movlw   9
    subwf   display_mes, 0
    btfsc   ZERO
    goto    septiembre
    
    movlw   10
    subwf   display_mes, 0
    btfsc   ZERO
    goto    octubre
    
    movlw   11
    subwf   display_mes, 0
    btfsc   ZERO
    goto    noviembre
    
    movlw   12
    subwf   display_mes, 0
    btfsc   ZERO
    goto    diciembre
    
enero:
    call    conversion_dia_31
    call    preparar_dia
    return
febrero:
    call    conversion_dia_28
    call    preparar_dia
    return

marzo:
    call    conversion_dia_31
    call    preparar_dia
    return
    
abril:
    call    conversion_dia_30
    call    preparar_dia
    return

mayo:
    call    conversion_dia_31
    call    preparar_dia
    return
    
junio:
    call    conversion_dia_30
    call    preparar_dia
    return
    
julio:
    call    conversion_dia_31
    call    preparar_dia
    return
    
agosto:
    call    conversion_dia_31
    call    preparar_dia
    return

septiembre:
    call    conversion_dia_30
    call    preparar_dia
    return
    
octubre:
    call    conversion_dia_31
    call    preparar_dia
    return
   
noviembre:
    call    conversion_dia_30
    call    preparar_dia
    return
    
diciembre:
    call    conversion_dia_31
    call    preparar_dia
    return
    
conversion_mes:
    movf    display_mes, W 
    
    
    wdivl   243		   
    movf    cociente, W
    movwf   decena	    
    movf    residuo, W
    movwf   unidad
    
    wdivl   13		    
    movf    cociente, W
    movwf   decena	    
    movf    residuo, W
    movwf   unidad
    
    wdivl   10		     
    movf    cociente, W
    movwf   decena	     
    movf    residuo, W
    movwf   unidad
    
    return
    
preparar_mes:
    movf    unidad, W	    
    call    tabla	   
    movwf   display_var+3   
    
    movf    decena, W	    
    call    tabla
    movwf   display_var+2 
    return

conversion_dia_31:
    movf    display_dia, W
    
    wdivl   224		   
    movf    cociente, W
    movwf   decena2	    
    movf    residuo, W
    movwf   unidad2
    
    wdivl   32		   
    movf    cociente, W
    movwf   decena2	   
    movf    residuo, W
    movwf   unidad2
   
    wdivl   10		     
    movf    cociente, W
    movwf   decena2	     
    movf    residuo, W
    movwf   unidad2
    return
    
conversion_dia_30:
    movf    display_dia, W 
    
    wdivl   225		 
    movf    cociente, W
    movwf   decena2	    
    movf    residuo, W
    movwf   unidad2
    
    wdivl   31		    
    movf    cociente, W
    movwf   decena2	    
    movf    residuo, W
    movwf   unidad2
   
    wdivl   10		     
    movf    cociente, W
    movwf   decena2	     
    movf    residuo, W
    movwf   unidad2
    return 
    
conversion_dia_28:
    movf    display_dia, W 
    
    wdivl   227		    
    movf    cociente, W
    movwf   decena2	    
    movf    residuo, W
    movwf   unidad2
    
    wdivl   29		   
    movf    cociente, W
    movwf   decena2	    
    movf    residuo, W
    movwf   unidad2
   
    wdivl   10		     
    movf    cociente, W
    movwf   decena2	   
    movf    residuo, W
    movwf   unidad2
    return   
    
preparar_dia:
    movf    unidad2, W	   
    call    tabla	    
    movwf   display_var+1   
    
    movf    decena2, W	    
    call    tabla
    movwf   display_var+0  
    return 

config_io:
    
    banksel ANSEL	; banco de ANSEL
   clrf ANSEL	; pines digitales
   clrf ANSELH

   banksel TRISA
   clrf TRISA	;PORTA como salida 
   clrf TRISB
   clrf TRISC
   clrf TRISD

   bcf  TRISD,0	; PORTD 0 como salida para transistores
   bcf  TRISD,1	; PORTD 1 como salida para transistores
   bcf  TRISD,2	; PORTD 2 como salida para transistores
   bcf  TRISD,3	; PORTD 3 como salida para transistores

   bsf	TRISB, UP1     ;Pínes 6 y 7 del PUERTO B como entradas
   bsf	TRISB, DOWN1
   bsf	TRISB, UP2
   bsf	TRISB, DOWN2
   bsf	TRISB, MODO

   bcf OPTION_REG, 7 ;activar los bit del puerto B como pull up

   bsf WPUB, 0     ;pines 6 y 7 como pull up
   bsf	WPUB, 1
   bsf WPUB, 2
   bsf  WPUB, 3
   bsf WPUB, MODO

   banksel PORTA	;Clear a puertos 
   clrf PORTA
   clrf PORTB
   clrf PORTC
   clrf PORTD
   clrf PORTE
   return    
    
config_reloj:
    banksel OSCCON  ;se selecciona con la directiva BANKSEL el banco del 
		    ;registro OSCCON para poder configurar el oscilador
    
		    ;poniendo el nombre de los bits 4,5,6 		    
		    ;se confiura a 500 KHz (
    bcf IRCF2	    ;(0) 500 KHz
    bsf IRCF1	    ; (1)
    bsf IRCF0	    ; (1)
    bsf SCS	    ; se pon en 1 el bit o para colocar el reloj interno
    return 
    
config_iocrb:
    banksel TRISA    ;banco 1 (01)
    bsf	    IOCB, MODO     
    bsf	    IOCB, UP1  
    bsf	    IOCB, UP2  
    bsf	    IOCB, DOWN1  
    bsf	    IOCB, DOWN2  	
    
    banksel PORTA
    movf    PORTB, W ;al leer termina condicion de bits no cooncistentes
    bcf	    RBIF     ;si no a terminado la condicion la bandera puede prenderse
    bsf	    GIE	    ;setear las interrupciones globales para habilitarlas 1
    bsf	    RBIE
    return

config_timer0:
    banksel TRISA   ;banco 1 (01)
		    ;configurar OPTION_REG 
    bcf	    T0CS    ;colocar el reloj interno
    bcf	    PSA	    ;assignar el prescaler para el modulo timer0
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	    ;PS = 111 -> configurar la razon de escala a 1:256 
     
    banksel PORTA
    reinicio_timer0
    return 
    
config_tmr1:
    banksel PORTA
    bcf	    TMR1GE  ;TMR1 este contando continuamente
    bsf	    T1CKPS1 ;prescaler 1:8 para contar dos veces x seg
    bsf	    T1CKPS0
    bcf	    T1OSCEN ;low power del oscilador apagado
    bcf	    TMR1CS  ;colocar el reloj interno 
    bsf	    TMR1ON  ;prender tmr1 
    reinicio_timer1 
    return
    
config_tmr2:	    ;compara valores
    banksel PORTA
    bcf	    TOUTPS3 ;postscaler 1:16
    bsf	    TOUTPS2
    bsf	    TOUTPS1
    bsf	    TOUTPS0
    
    bsf	    TMR2ON
    bsf	    T2CKPS1 ;prescaler 16
    bsf	    T2CKPS0
    
    ;PR2 = 500mseg/16*16*1*(500 KHz/4)) = 244
    banksel TRISB
    movwf   244
    movwf   PR2
    clrf    TMR2
    bcf	    TMR2IF
    return
    
config_interrupcion:
    banksel TRISA
    bsf	    TMR1IE  ;interrpcion TMR1
    bsf	    TMR2IE  ;interrpcion TMR2
    banksel PORTA
    bsf	    T0IE    ;habilitar interrupcion TMR0 1
    bcf	    T0IF    ;limpiar la bandera 1
    bcf	    TMR1IF  ;bandera tmr1
    bcf	    TMR2IF  ;bandera tmr2
    
    bsf	    PEIE    ;interrupciones perifericas
    bsf	    GIE	    ;setear las interrupciones globales para habilitarlas 1
    return 
end
    
    
    
