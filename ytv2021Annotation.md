## The label file follows MSCOCO's style in json format. We adapt the entry name and label format for video. The definition of json file is:

<!-- PROJECT SHIELDS -->

{\
            "info" : info, \
            "videos" : [video], \
            "annotations" : [annotation], \
            "categories" : [category], \
        } \
        video{ \
            "id" : int, \
            "width" : int, \
            "height" : int, \
            "length" : int, \
            "file_names" : [file_name], \
        } \
        annotation{ \
            "id" : int,  \
            "video_id" : int,  \
            "category_id" : int,  \
            "segmentations" : [RLE or [polygon] or None],  \
            "areas" : [float or None],  \
            "bboxes" : [[x,y,width,height] or None],  \
            "iscrowd" : 0 or 1, \
        } \
        category{ \
            "id" : int,  \
            "name" : str,  \
            "supercategory" : str, \
        } \
    
    
    
<!-- PROJECT SHIELDS -->
## The submission file is also in json format. The file should contain a list of predictions:

prediction{ \
            "video_id" : int,  \
            "category_id" : int,  \
            "segmentations" : [RLE or [polygon] or None],  \
            "score" : float,  \
        } \

    
    
    
