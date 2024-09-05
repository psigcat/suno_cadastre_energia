from suno_task import SunoTask


def main_app():
    """ Create main application """

    try:
        cod_muni = "17049"
        suno_task = SunoTask(cod_muni)  
        if suno_task.init_db():
            suno_task.run()
    except Exception as e:
        print(f"{e}")


if __name__ == "__main__":
    main_app()