*** Settings ***
Library           RPA.Browser.Selenium
Library           RPA.PDF
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.FileSystem

*** Variables ***
${URL}            https://robotsparebinindustries.com/#/robot-order
${OUTPUT_DIR}     output
${ZIP_FILE_PATH}  ${OUTPUT_DIR}${/}receipts.zip

*** Keywords ***
Open the robot order website
    Open Available Browser  ${URL}
    Maximize Browser Window

Close the annoying modal
    Wait Until Element Is Visible  xpath=//*[@id="root"]/div/div[2]/div/div/div/div
    Click Element  xpath=//*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Get orders
    @{orders}=  Read Table From Csv  orders.csv
    [Return]  ${orders}

Go to order another robot
    Sleep  2s
    Click Element  id:order-another
    Close the annoying modal

Fill the form
    [Arguments]  ${order}
    ${head}=  Set Variable  ${order}[Head]
    ${body}=  Set Variable  ${order}[Body]
    ${legs}=  Set Variable  ${order}[Legs]
    ${address}=  Set Variable  ${order}[Address]
    Select From List By Value  id:head  ${head}
    Click Element  xpath://input[@type='radio' and @name='body' and @value='${body}']
    Input Text  xpath://*[@type='number' and @placeholder='Enter the part number for the legs']  ${legs}
    Input Text  id:address  ${address}
    Click Button  id:order

Store the receipt as a PDF file
    [Arguments]  ${order_number}
    ${receipt_path}=  Set Variable  ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf
    Capture Page Screenshot  ${receipt_path}
    [Return]  ${receipt_path}

Take a screenshot of the robot
    [Arguments]  ${order_number}
    ${screenshot_path}=  Set Variable  ${OUTPUT_DIR}${/}screenshots${/}${order_number}.png
    Capture Page Screenshot  ${screenshot_path}
    [Return]  ${screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]  ${screenshot}  ${pdf}
    ${html_path}=  Set Variable  ${OUTPUT_DIR}${/}temp.html
    Log To Console  \nCreating HTML file at: ${html_path}
    Create File  ${html_path}  <html><body><img src="${screenshot}" alt="screenshot"></body></html>
    Log To Console  \nConverting HTML to PDF...
    Html To Pdf  ${html_path}  ${pdf}
    Log To Console  \nPDF created at: ${pdf}
    Remove File  ${html_path}
    Log To Console  \nTemporary HTML file removed.

Create ZIP Archive of Receipt PDF Files
    ${pdf_files}=  Get File Names In Directory  ${OUTPUT_DIR}${/}receipts
    Create ZIP Archive  ${ZIP_FILE_PATH}  ${pdf_files}

*** Tasks ***
Automate Robot Orders
    Open the robot order website
    Close the annoying modal
    SLEEP    1
    ${orders}=  Get orders
    FOR  ${order}  IN  @{orders}
        Fill the form  ${order}
        ${pdf}=  Store the receipt as a PDF file  ${order}[Order number]
        ${screenshot}=  Take a screenshot of the robot  ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file  ${screenshot}  ${pdf}
        Go to order another robot
    END
     Create ZIP Archive of Receipt PDF Files

