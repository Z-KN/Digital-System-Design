/***************************�����Ƶ���****************************
**  �������ƣ�YS-V0.7����ʶ��ģ����������
**	CPU: STC11L08XE
**	����22.1184MHZ
**	�����ʣ�9600 bit/S
**	���ײ�Ʒ��Ϣ��YS-V0.7����ʶ�𿪷���
**                http://yuesheng001.taobao.com
**  ���ߣ�zdings
**  ��ϵ��751956552@qq.com
**  �޸����ڣ�2013.9.13
**  ˵��������ģʽ+IO���ƣ� ��ÿ��ʶ��ʱ����Ҫ˵��С�ܡ�������� �����ܹ�������һ����ʶ��
/***************************�����Ƶ���******************************/
#include "config.h"
/************************************************************************************/
//	nAsrStatus ������main�������б�ʾ�������е�״̬������LD3320оƬ�ڲ���״̬�Ĵ���
//	LD_ASR_NONE:		��ʾû������ASRʶ��
//	LD_ASR_RUNING��		��ʾLD3320������ASRʶ����
//	LD_ASR_FOUNDOK:		��ʾһ��ʶ�����̽�������һ��ʶ����
//	LD_ASR_FOUNDZERO:	��ʾһ��ʶ�����̽�����û��ʶ����
//	LD_ASR_ERROR:		��ʾһ��ʶ��������LD3320оƬ�ڲ����ֲ���ȷ��״̬
/***********************************************************************************/
uint8 idata nAsrStatus=0;	
void MCU_init(); 
void ProcessInt0(); //ʶ��������
void  delay(unsigned long uldata);
void 	User_handle(uint8 dat);//�û�ִ�в�������
void Led_test(void);//��Ƭ������ָʾ
void Delay200ms();
uint8_t G0_flag=DISABLE;//���б�־��ENABLE:���С�DISABLE:��ֹ���� 
sbit LED=P4^2;//�ź�ָʾ��
//Ӧ��IO�ڶ��� ��ģ���ע P2��
/*
sbit PA1=P1^0; //��Ӧ���ϱ�� P1.0
sbit PA2=P1^1;  //��Ӧ���ϱ�� P1.1
sbit PA3=P1^2;  //.....
sbit PA4=P1^3;  //.....
sbit PA5=P1^4;  //.....
sbit PA6=P1^5;  //.....
sbit PA7=P1^6;  //��Ӧ���ϱ�� P1.6
sbit PA8=P1^7;  //��Ӧ���ϱ�� P1.7
*/
sbit LED1=P1^0;
sbit LED2=P1^1;
sbit LED3=P1^2;
sbit ALMC=P1^4;
sbit MUSIC=P1^5;

/***********************************************************
* ��    �ƣ� void  main(void)
* ��    �ܣ� ������	�������
* ��ڲ�����  
* ���ڲ�����
* ˵    ���� 					 
* ���÷����� 
**********************************************************/ 
void  main(void)
{
	uint8 idata nAsrRes;
	uint8 i=0;
	Led_test();
	MCU_init();
	LD_Reset();
	UartIni(); /*���ڳ�ʼ��*/
	nAsrStatus = LD_ASR_NONE;		//	��ʼ״̬��û������ASR
	
	#ifdef TEST	
	PrintCom("���1������1\r\n"); /*text.....*/
	PrintCom("	   2������2\r\n"); /*text.....*/
	PrintCom("	   3������3\r\n"); /*text.....*/
	PrintCom("	   4���ص�1\r\n"); /*text.....*/
	PrintCom("     5���ص�2\r\n"); /*text.....*/
	PrintCom("	   6���ص�3\r\n"); /*text.....*/
	PrintCom("     7������\r\n"); /*text.....*/
	PrintCom("     8���ص�\r\n"); /*text.....*/
	PrintCom("	   9��������\r\n"); /*text.....*/
	PrintCom(" 	   10��������\r\n"); /*text.....*/
	#endif

	while(1)
	{
		switch(nAsrStatus)
		{
			case LD_ASR_RUNING:
			case LD_ASR_ERROR:		
				break;
			case LD_ASR_NONE:
			{
				nAsrStatus=LD_ASR_RUNING;
				if (RunASR()==0)	/*	����һ��ASRʶ�����̣�ASR��ʼ����ASR���ӹؼ��������ASR����*/
				{
					nAsrStatus = LD_ASR_ERROR;
				}
				break;
			}
			case LD_ASR_FOUNDOK: /*	һ��ASRʶ�����̽�����ȥȡASRʶ����*/
			{				
				nAsrRes = LD_GetResult();		/*��ȡ���*/
				User_handle(nAsrRes);//�û�ִ�к��� 
				nAsrStatus = LD_ASR_NONE;
				break;
			}
			case LD_ASR_FOUNDZERO:
			default:
			{
				nAsrStatus = LD_ASR_NONE;
				break;
			}
		}// switch	 			
	}// while

}
/***********************************************************
* ��    �ƣ� 	 LED�Ʋ���
* ��    �ܣ� ��Ƭ���Ƿ���ָʾ
* ��ڲ����� �� 
* ���ڲ�������
* ˵    ���� 					 
**********************************************************/
void Led_test(void)
{
	LED=~ LED;
	Delay200ms();
	LED=~ LED;
	Delay200ms();
	LED=~ LED;
	Delay200ms();
	LED=~ LED;
	Delay200ms();
	LED=~ LED;
	Delay200ms();
	LED=~ LED;
}
/***********************************************************
* ��    �ƣ� void MCU_init()
* ��    �ܣ� ��Ƭ����ʼ��
* ��ڲ�����  
* ���ڲ�����
* ˵    ���� 					 
* ���÷����� 
**********************************************************/ 
void MCU_init()
{
	P0 = 0xff;
	P1 = 0x00;
	P2 = 0xff;
	P3 = 0xff;
	P4 = 0xff;
	P1M1=0;
	P1M0=0xff;
	LD_MODE = 0;		//	����MD�ܽ�Ϊ�ͣ�����ģʽ��д
	IE0=1;
	EX0=1;
	EA=1;
}
/***********************************************************
* ��    �ƣ�	��ʱ����
* ��    �ܣ�
* ��ڲ�����  
* ���ڲ�����
* ˵    ���� 					 
* ���÷����� 
**********************************************************/ 
void Delay200us()		//@22.1184MHz
{
	unsigned char i, j;
	_nop_();
	_nop_();
	i = 5;
	j = 73;
	do
	{
		while (--j);
	} while (--i);
}

void  delay(unsigned long uldata)
{
	unsigned int j  =  0;
	unsigned int g  =  0;
	while(uldata--)
	Delay200us();
}

void Delay200ms()		//@22.1184MHz
{
	unsigned char i, j, k;

	i = 17;
	j = 208;
	k = 27;
	do
	{
		do
		{
			while (--k);
		} while (--j);
	} while (--i);
}

/***********************************************************
* ��    �ƣ� �жϴ�������
* ��    �ܣ�
* ��ڲ�����  
* ���ڲ�����
* ˵    ���� 					 
* ���÷����� 
**********************************************************/ 
void ExtInt0Handler(void) interrupt 0  
{ 	
	ProcessInt0();				/*	LD3320 �ͳ��ж��źţ�����ASR�Ͳ���MP3���жϣ���Ҫ���жϴ��������зֱ���*/
}
/***********************************************************
* ��    �ƣ��û�ִ�к��� 
* ��    �ܣ�ʶ��ɹ���ִ�ж������ڴ˽����޸� 
* ��ڲ����� �� 
* ���ڲ�������
* ˵    ���� ͨ������PAx�˿ڵĸߵ͵�ƽ���Ӷ������ⲿ�̵�����ͨ��					 
**********************************************************/
void 	User_handle(uint8 dat)
{
			 switch(dat)		   /*�Խ��ִ����ز���,�ͻ��޸�*/
			  {
				  case CODE_KFBYZ:			/*������ԡ�*/
						PrintCom("������1������ʶ��ɹ�\r\n"); //���������ʾ��Ϣ����ɾ����
						LED1=1;
						
													 break;
					case CODE_DMCS:	 /*���ȫ����*/
						PrintCom("������2������ʶ��ɹ�\r\n");//���������ʾ��Ϣ����ɾ����
						LED2=1;
					
													 break;
					case CODE_KD:		/*�����λ��*/				
						PrintCom("������3������ʶ��ɹ�\r\n"); //���������ʾ��Ϣ����ɾ����
						LED3=1;
						
													break;
					case CODE_GD:		/*�����λ��*/				
						PrintCom("���ص�1������ʶ��ɹ�\r\n"); //���������ʾ��Ϣ����ɾ����
						LED1=0;
					
													break;
					case CODE_BJ:		/*�����λ��*/				
						PrintCom("���ص�2������ʶ��ɹ�\r\n"); //���������ʾ��Ϣ����ɾ����
						LED2=0;
						
													break;
					case CODE_SH:		/*�����λ��*/				
						PrintCom("���ص�3������ʶ��ɹ�\r\n"); //���������ʾ��Ϣ����ɾ����
						LED3=0;
													break;
					case CODE_GZ:		/*�����λ��*/				
						PrintCom("�����ơ�����ʶ��ɹ�\r\n"); //���������ʾ��Ϣ����ɾ����
						LED1=1;
						LED2=1;
						LED3=1;
													break;	
					case CODE_GDA:		/*�����λ��*/				
						PrintCom("���صơ�����ʶ��ɹ�\r\n"); //���������ʾ��Ϣ����ɾ����
						LED1=0;
						LED2=0;
						LED3=0;
					
													break;
					case CODE_GSY:						
						PrintCom("��������������ʶ��ɹ�\r\n"); //���������ʾ��Ϣ����ɾ����
						ALMC=1;
						MUSIC=1;
													break;
					case CODE_FYY:				
						PrintCom("�������֡�����ʶ��ɹ�\r\n"); //���������ʾ��Ϣ����ɾ����
						MUSIC=1;
						ALMC=0;
													break;	
						case CODE_NHYY:				
						PrintCom("��������ơ�����ʶ��ɹ�\r\n"); //���������ʾ��Ϣ����ɾ����
						MUSIC=0;
						ALMC=0;
													break;																										
							default:PrintCom("������ʶ�𷢿���\r\n"); //���������ʾ��Ϣ����ɾ����
													break;
				}	
}	 