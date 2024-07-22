# Преобразование  xsd в htmlform

Исходники взяты из https://github.com/MichielCM/xsd2html2xml



### Проблемы при компиляции
``java.lang.RuntimeException: XPATH_LIMIT``

Использовать версию java 1.8.275

Или использовать параметры для запуска JVM:

``
-Djdk.xml.xpathExprGrpLimit=0
-Djdk.xml.xpathExprOpLimit=0
-Djdk.xml.xpathTotalOpLimit=0 
-Xmx2g 
-Xms512m 
-XX:-UseGCOverheadLimit
``
