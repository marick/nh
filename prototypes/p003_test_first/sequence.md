Entering a paragraph
    send "start" to PARAGRAPH-FOCUS
    send "start" to HOMEOSTASIS-BIG-EDIT
        instruct an EYE-FLICKER to big-edit marker
            a short delay then sends instruction to send affordance to HOMEOSTASIS-BIG-EDIT
            homeostasis-big-edit accepts the value
            another eye-flicker
            if value doesn't match, wait a set of eye flickers, then SHOW-BIG-EDIT via PARAGRAPH FOCUS
            
                motor has expectation of paragraph (3 words + 10% length)
            
leaving a paragraph
    stop homeostasis big edit
    pause, then signal entering-paragraph to start its homeostasis up
            


**paragraph-focus**
   - starts all paragraph homeostasis 
   - accepts changes to paragraph and keeps track of their recency
     - forwards same to all circular processes
   - on **switch to new**
     - shuts down all homeostasis
     - discards all messages for a saccade time
     - sends delayed message to start new paragraph focus
     - accepts new messages and forwards if rough-shape is acceptable.
   - on change
     - set jitter clock??
     


Any paragraph-tied circular process
    initialized and updated with rough paragraph shape
    gets updated as shape changes
    when shutting down, discards further processes
    
    
    
shift focus 

notice change out of corner of eye - updates only self and only change count. 

glance - update identical count

paragraph shape 
    changed
    beats sincd last change
    
    
    
    
homeostasis start
    paragraph shape
    if editing - start border-color with paragraph shape 
    glance at border for same 
    
    ensure-editing-border with-alert 
    
