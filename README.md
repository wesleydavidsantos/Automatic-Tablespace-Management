# Automatic-Tablespace-Management

Hello, fellow DBA! This script was created with the purpose of simplifying those daily analyses and maintenance tasks that are usually not very exciting but are crucial.

Every DBA knows how stressful it can be when the phone starts ringing incessantly because a tablespace has reached its storage limit. Given that tablespace maintenance is a repetitive process, why not automate it? It was with this thought in mind that I developed a script capable of performing this analysis and maintenance automatically. It also generates a log whenever maintenance is executed, ensuring that you have a daily report at your disposal.

A significant advantage of this automatic tablespace management system is that the DBA does not need to allocate an excessive amount of disk space to prevent abnormal database growth during unexpected loads. The automatic management system itself takes care of allocating more space when needed.

The metric used to determine when additional space needs to be allocated is obtained through a query that I have already presented in another article on LinkedIn. You can find it here: https://www.linkedin.com/pulse/tablespace-de-tamanho-relativo-voc%25C3%25AA-j%25C3%25A1-ouviu-falar-david-santos/

Below, I present the script to create the necessary objects for this automatic management, which are just three: a Sequence, a Table, and a Package.

Note: It is important to configure Oracle Managed Files (OMF) in the database. Additionally, this automatic management applies only to tablespaces, so you should still monitor disk usage or Automatic Storage Management (ASM). However, stay tuned, as I will soon publish a script to automate disk or ASM monitoring.




# Realiza o Gestão e Expansão Automática das Tablespaces do Oracle


Gestão automática de Tablespace

Olá, colega DBA! Este script foi criado com o propósito de simplificar aquelas análises e manutenções diárias que geralmente não são nada empolgantes, mas são cruciais.

Todo DBA sabe o quão estressante é quando o telefone começa a tocar incessantemente porque uma tablespace atingiu seu limite de armazenamento. Dado que a manutenção de tablespaces é um processo repetitivo, por que não automatizá-lo? Foi com esse pensamento que desenvolvi um script capaz de realizar essa análise e manutenção de forma automatizada. Ele também gera um log sempre que a manutenção é executada, garantindo que você tenha um relatório diário à sua disposição.

Uma grande vantagem desse sistema de gerenciamento automático de tablespaces é que o DBA não precisa alocar uma quantidade excessiva de espaço em disco para prevenir um crescimento anormal do banco de dados durante cargas inesperadas. O próprio sistema de gerenciamento automático se encarrega de alocar mais espaço quando necessário.

A métrica usada para determinar quando é necessário alocar mais espaço é obtida por meio de uma consulta que já apresentei em outro artigo no LinkedIn. Você pode encontrá-lo aqui: https://www.linkedin.com/pulse/tablespace-de-tamanho-relativo-voc%25C3%25AA-j%25C3%25A1-ouviu-falar-david-santos/

A seguir, apresento o script para criar os objetos necessários para esse gerenciamento automático, que são apenas três: uma Sequence, uma Table e uma Package.

Observação: É importante configurar o OMF (Oracle Managed Files) no banco de dados. Além disso, este gerenciamento automático se aplica apenas às tablespaces, portanto, você ainda deve monitorar o uso de disco ou ASM (Automatic Storage Management). No entanto, fique ligado, pois em breve publicarei um script para automatizar o monitoramento de disco ou ASM.
